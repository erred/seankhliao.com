# go webauthn passkeys

## implementing login without passwords.

### _webauthn_ and passkeys in go

Previously I had my private services running in a [Tailscale](https://tailscale.com/) tailnet (vpn).
I still love them, but... my Pixel 8 can't connect to multiple VPNs at once:
I have Tailscale for private stuff,
Google One for general purpose.
So it's time to do zero trust and implement proper auth into applications.

#### _webauthn_

[WebAuthn](https://webauthn.io/) has been around for a while,
primarily used as an unphishable second factor:
you provide a username, and password, and your hardware key signs a challenge from the server.
It's unphishable because: it's hardware you need physical control over,
and because the client (browser) is coopted into the security flow so challenges are domain bound:
so typo domain squatting doesn't work, you can't relay a challenge from a different site
By just signing the challenge, the hardware keys don't need to store any data for each site its used with.
While commonly used as a second factor,
it could in theory be used for passwordless flows with just a usernme.

WebAuthn/Fido2 also had a different way of working: Resident Keys,
also known as Discoverable Credentials,
or the most recent rebrand: [Passkeys](https://fidoalliance.org/passkeys/).
This time the hardware key stores a dedicated key per relying party (site) and userid pair,
allowing a site to directly query for a user.
This in theory enables just using a usernameless/passwordless flow,
but most large sites tend to ask for the username anyway.
Because the hardware key is storing dedicated key material,
the number of usable keys are somewhat limited (25 for a yubikey 5).

#### _implementing_ in go

[`github.com/go-webauthn/webauthn`](https://pkg.go.dev/github.com/go-webauthn/webauthn)
is pretty much the only implementation, and it's fine.
On the Go side, it's primarily
[`BeginDiscoverableLogin`](https://pkg.go.dev/github.com/go-webauthn/webauthn/webauthn#WebAuthn.BeginDiscoverableLogin),
securely store the session data (eg as a secure cookie),
and verify with
[`FinishDisoverableLogin`](https://pkg.go.dev/github.com/go-webauthn/webauthn/webauthn#WebAuthn.FinishDiscoverableLogin).
You'll want cookies to offload all the session datas to clients.
My code can be found here:
[`go.seankhliao.com/mono/cmd/authsvr`](https://github.com/seankhliao/mono/tree/447c1b39c065e9cae82e617dd3133bf31423c249/cmd/authsvr).

```go
func (a *App) startLogin() http.Handler {
        return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
                ctx, span := a.o.T.Start(r.Context(), "startLogin")
                defer span.End()

                data, wanSess, err := a.wan.BeginDiscoverableLogin()
                if err != nil {
                        a.jsonErr(ctx, rw, "webauthn begin login", err, http.StatusInternalServerError, struct{}{})
                        return
                }

                wanSessCook, err := a.storeSecret("webauthn_login_start", wanSess)
                if err != nil {
                        a.jsonErr(ctx, rw, "store session data", err, http.StatusInternalServerError, struct{}{})
                        return
                }
                http.SetCookie(rw, wanSessCook)

                a.jsonOk(ctx, rw, data)
        })
}

type LoginResponse struct {
        Status   string `json:"status"`
        Redirect string `json:"redirect,omitempty"`
}

func (a *App) finishLogin() http.Handler {
        return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
                ctx, span := a.o.T.Start(r.Context(), "finishLogin")
                defer span.End()

                wanSessCook, err := r.Cookie("webauthn_login_start")
                if err != nil {
                        a.jsonErr(ctx, rw, "get session cookie", err, http.StatusBadRequest, struct{}{})
                        return
                }
                var wanSess webauthn.SessionData
                err = a.readSecret("webauthn_login_start", wanSessCook, &wanSess)
                if err != nil {
                        a.jsonErr(ctx, rw, "read session cookie", err, http.StatusBadRequest, struct{}{})
                        return
                }

                // check
                // rawID == credential id
                // userHandle == user.id in creation request (from user.WebAuthnID)
                handler := func(rawID, userHandle []byte) (webauthn.User, error) {
                        var user User
                        err := a.db.View(func(tx *bbolt.Tx) error {
                                bkt := tx.Bucket(bucketUser)
                                b := bkt.Get(userHandle)
                                err := json.Unmarshal(b, &user)
                                if err != nil {
                                        return fmt.Errorf("decode user data: %w", err)
                                }
                                return nil
                        })
                        return user, err
                }
                cred, err := a.wan.FinishDiscoverableLogin(handler, wanSess, r)
                if err != nil {
                        a.jsonErr(ctx, rw, "webauthn finish login", err, http.StatusBadRequest, struct{}{})
                        return
                }

                if cred.Authenticator.CloneWarning {
                        a.jsonErr(ctx, rw, "cloned authenticator", err, http.StatusBadRequest, struct{}{})
                        return
                }

                rawSessToken := make([]byte, 32)
                rand.Read(rawSessToken)
                sessToken := hex.EncodeToString(rawSessToken)
                http.SetCookie(rw, &http.Cookie{
                        Name:     AuthCookieName,
                        Value:    sessToken,
                        Path:     "/",
                        Domain:   a.cookieDomain,
                        MaxAge:   60 * 60 * 24 * 365,
                        HttpOnly: true,
                        Secure:   true,
                        SameSite: http.SameSiteLaxMode,
                })

                err = a.db.Update(func(tx *bbolt.Tx) error {
                        bkt := tx.Bucket(bucketCred)
                        email := bkt.Get(cred.ID)
                        bkt = tx.Bucket(bucketUser)
                        b := bkt.Get(email)
                        var user User
                        err := json.Unmarshal(b, &user)
                        if err != nil {
                                return fmt.Errorf("decode user data: %w", err)
                        }
                        for i := range user.Creds {
                                if string(user.Creds[i].ID) == string(cred.ID) {
                                        user.Creds[i].Authenticator.SignCount = cred.Authenticator.SignCount
                                        break
                                }
                        }
                        b, err = json.Marshal(user)
                        if err != nil {
                                return fmt.Errorf("encode user data: %w", err)
                        }
                        err = bkt.Put(email, b)
                        if err != nil {
                                return fmt.Errorf("update user data: %w", err)
                        }

                        info := SessionInfo{
                                UserID:      user.ID,
                                Email:       user.Email,
                                StartTime:   time.Now(),
                                UserAgent:   r.UserAgent(),
                                LoginCredID: hex.EncodeToString(cred.ID),
                        }
                        b, err = json.Marshal(info)
                        if err != nil {
                                return fmt.Errorf("encode sesion info: %w", err)
                        }

                        bkt = tx.Bucket(bucketSession)
                        err = bkt.Put([]byte(sessToken), b)
                        if err != nil {
                                return fmt.Errorf("store session token: %w", err)
                        }

                        return nil
                })
                if err != nil {
                        a.jsonErr(ctx, rw, "create new session", err, http.StatusBadRequest, struct{}{})
                        return
                }

                res := LoginResponse{
                        Status: "ok",
                }

                u, err := url.Parse(r.FormValue("redirect"))
                if err == nil {
                        if strings.HasSuffix(u.Hostname(), "liao.dev") {
                                res.Redirect = u.String()
                        }
                }

                a.jsonOk(ctx, rw, res)
        })
}

func (a *App) registerStart() http.Handler {
        return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
                ctx := r.Context()
                ctx, span := a.o.T.Start(ctx, "registerStart")
                defer span.End()

                adminKey := r.FormValue("adminkey")
                if adminKey != a.adminKey {
                        a.jsonErr(ctx, rw, "mismatched admin key", errors.New("unauthed admin key"), http.StatusUnauthorized, struct{}{})
                        return
                }

                email := r.PathValue("email")
                if email == "" {
                        a.jsonErr(ctx, rw, "empty email pathvalue", errors.New("no email"), http.StatusBadRequest, struct{}{})
                        return
                }

                var user User
                err := a.db.Update(func(tx *bbolt.Tx) error {
                        bkt := tx.Bucket(bucketUser)
                        b := bkt.Get([]byte(email))
                        if len(b) == 0 {
                                user.Email = email
                                id, _ := rand.Int(rand.Reader, big.NewInt(math.MaxInt64))
                                user.ID = id.Int64()
                                b, err := json.Marshal(user)
                                if err != nil {
                                        return fmt.Errorf("marshal new user: %w", err)
                                }
                                return bkt.Put([]byte(email), b)
                        }
                        return json.Unmarshal(b, &user)
                })
                if err != nil {
                        a.jsonErr(ctx, rw, "get user from email", err, http.StatusInternalServerError, struct{}{})
                        return
                }

                var exlcusions []protocol.CredentialDescriptor
                for _, cred := range user.Creds {
                        exlcusions = append(exlcusions, cred.Descriptor())
                }

                data, wanSess, err := a.wan.BeginRegistration(user, webauthn.WithExclusions(exlcusions))
                if err != nil {
                        a.jsonErr(ctx, rw, "webauthn begin registration", err, http.StatusInternalServerError, struct{}{})
                        return
                }

                wanSessCook, err := a.storeSecret("webauthn_register_start", wanSess)
                if err != nil {
                        a.jsonErr(ctx, rw, "store session cookie", err, http.StatusInternalServerError, struct{}{})
                        return
                }
                http.SetCookie(rw, wanSessCook)

                a.jsonOk(ctx, rw, data)
        })
}

func (a *App) registerFinish() http.Handler {
        return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
                ctx := r.Context()
                ctx, span := a.o.T.Start(ctx, "registerFinish")
                defer span.End()

                adminKey := r.FormValue("adminkey")
                if adminKey != a.adminKey {
                        a.jsonErr(ctx, rw, "mismatched admin key", errors.New("unauthed admin key"), http.StatusUnauthorized, struct{}{})
                        return
                }

                email := r.PathValue("email")
                if email == "" {
                        a.jsonErr(ctx, rw, "empty email pathvalue", errors.New("no email"), http.StatusBadRequest, struct{}{})
                        return
                }

                wanSessCook, err := r.Cookie("webauthn_register_start")
                if err != nil {
                        a.jsonErr(ctx, rw, "get session cookie", err, http.StatusBadRequest, struct{}{})
                        return
                }
                var wanSess webauthn.SessionData
                err = a.readSecret("webauthn_register_start", wanSessCook, &wanSess)
                if err != nil {
                        a.jsonErr(ctx, rw, "decode session cookie", err, http.StatusBadRequest, struct{}{})
                        return
                }

                err = a.db.Update(func(tx *bbolt.Tx) error {
                        bkt := tx.Bucket(bucketUser)
                        b := bkt.Get([]byte(email))
                        var user User
                        err := json.Unmarshal(b, &user)
                        if err != nil {
                                return fmt.Errorf("decode user: %w", err)
                        }

                        cred, err := a.wan.FinishRegistration(user, wanSess, r)
                        if err != nil {
                                return fmt.Errorf("finish registration: %w", err)
                        }
                        user.Creds = append(user.Creds, *cred)

                        b, err = json.Marshal(user)
                        if err != nil {
                                return fmt.Errorf("encode user: %w", err)
                        }

                        err = bkt.Put([]byte(email), b)
                        if err != nil {
                                return fmt.Errorf("update user")
                        }

                        bkt = tx.Bucket(bucketCred)
                        err = bkt.Put(cred.ID, []byte(email))
                        if err != nil {
                                return fmt.Errorf("link cred to user")
                        }
                        return nil
                })
                if err != nil {
                        a.jsonErr(ctx, rw, "store registration", err, http.StatusInternalServerError, err)
                        return
                }

                a.jsonOk(ctx, rw, struct{}{})
        })
}
```

On the client side, javascript is a necessity to call the `navigator.credentials`
[Web Authentication API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API).
Also some helper functions to turn Go base64 bytes to the right encoding:

```javascript
// Base64url encode / decode, used by webauthn https://www.w3.org/TR/webauthn-2/
function bufferEncode(value) {
  return btoa(String.fromCharCode.apply(null, new Uint8Array(value)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}
function bufferDecode(value) {
  return Uint8Array.from(
    atob(value.replace(/-/g, "+").replace(/_/g, "/")),
    (c) => c.charCodeAt(0),
  );
}
// login
async function loginUser() {
  const startResponse = await fetch("/login/start", {
    method: "POST",
  });
  if (!startResponse.ok) {
    alert("failed to start");
    return;
  }
  let opts = await startResponse.json();
  opts.publicKey.challenge = bufferDecode(opts.publicKey.challenge);
  if (opts.publicKey.allowCredentials) {
    opts.publicKey.allowCredentials.forEach(
      (it) => (it.id = bufferDecode(it.id)),
    );
  }
  const assertion = await navigator.credentials.get({
    publicKey: opts.publicKey,
  });

  // technically possible to do this all client side?
  let windowParams = new URLSearchParams(document.location.search);
  let params = new URLSearchParams({ redirect: windowParams.get("redirect") });
  const finishResponse = await fetch(`/login/finish?${params}`, {
    method: "POST",
    body: JSON.stringify({
      id: assertion.id,
      rawId: bufferEncode(assertion.rawId),
      type: assertion.type,
      response: {
        authenticatorData: bufferEncode(assertion.response.authenticatorData),
        clientDataJSON: bufferEncode(assertion.response.clientDataJSON),
        signature: bufferEncode(assertion.response.signature),
        userHandle: bufferEncode(assertion.response.userHandle),
      },
    }),
  });
  if (!finishResponse.ok) {
    alert("failed to login");
    return;
  }
  const loginStatus = await finishResponse.json();
  if (loginStatus.redirect) {
    window.location.href = loginStatus.redirect;
    return;
  }
  window.location.reload();
}
// register
async function registerUser() {
  let email = encodeURIComponent(document.querySelector("#email").value);
  let adminKey = document.querySelector("#adminkey").value;
  let params = new URLSearchParams({ adminkey: adminKey });

  const startResponse = await fetch(`/register/${email}/start?${params}`, {
    method: "POST",
  });
  if (!startResponse.ok) {
    alert("failed to start");
  }
  let opts = await startResponse.json();
  opts.publicKey.challenge = bufferDecode(opts.publicKey.challenge);
  opts.publicKey.user.id = bufferDecode(opts.publicKey.user.id);
  if (opts.publicKey.excludeCredentials) {
    opts.publicKey.excludeCredentials.forEach(
      (it) => (it.id = bufferDecode(it.id)),
    );
  }
  const cred = await navigator.credentials.create({
    publicKey: opts.publicKey,
  });
  const finishResponse = await fetch(`/register/${email}/finish?${params}`, {
    method: "POST",
    body: JSON.stringify({
      id: cred.id,
      rawId: bufferEncode(cred.rawId),
      type: cred.type,
      response: {
        attestationObject: bufferEncode(cred.response.attestationObject),
        clientDataJSON: bufferEncode(cred.response.clientDataJSON),
      },
    }),
  });
  if (!finishResponse.ok) {
    alert("failed to register");
    return;
  }
  alert("registered, plz login");
}
```
