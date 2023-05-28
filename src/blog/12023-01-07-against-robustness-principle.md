# against robustnest principle

## robust... or not?

### _robustness_ principle

[RFC 761 Section 2.10] Transmission Control Protocol: Philosophy: Robustness Principle:

> be conservative in what you do, be liberal in what you accept from others

Also known as Postel's Law (after the author Jon Postel),
it stated without justification.

On the face of it,
it would appear to be a good idea,
especially for short term "get things working" scenarios.
You be a good citizen by producing spec compliant output,
while tolerating deviations in your input.

#### _no_

Of course, not everyone reads or cares about the spec.
They may instead just test against implementations,
and if it works, job done.

Which invites the following [corollary] of the robustness principle:

> If you are liberal in what you accept, others will utterly fail to be conservative in what they sen

The effects are described in [RFC 3117 Section 4.5]
On the Design of Application Protocols: Protocol Properties: Robustness,
with regards to gradual rollout in an uncoordinated world.

Most recently,
[Internet Draft: Maintaining Robust Protocols]
goes into more words on the [Harmful Consequences of Tolerating the Unexpected].
Key quotes would be

> In particular,
> tolerating unexpected behavior is particularly deleterious for early implementations of new protocols
> as quirks in early implementations can affect all subsequent deployments.

> An accumulation of mitigations for interoperability issues
> makes implementations more difficult to maintain and can constrain extensibility.

[rfc 761 section 2.10]: https://datatracker.ietf.org/doc/html/rfc761#section-2.10
[corollary]: https://hg.mozilla.org/integration/mozilla-inbound/file/9b2a99adc05e/js/src/jsscan.c#l1612
[rfc 3117 section 4.5]: https://datatracker.ietf.org/doc/html/rfc3117#section-4.5
[internet draft: maintaining robust protocols]: https://datatracker.ietf.org/doc/html/draft-iab-protocol-maintenance
[harmful consequences of tolerating the unexpected]: https://datatracker.ietf.org/doc/html/draft-iab-protocol-maintenance#name-harmful-consequences-of-tol
