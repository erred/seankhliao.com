CONVERT_SVG := convert -background none -density 150

.PHONY: map
map: map.png map.avif
map.png: map.svg
	$(CONVERT_SVG) -resize 1920x1080 $? $@
map.avif: map.svg
	$(CONVERT_SVG) -resize 1920x1080 $? $@

.PHONY: icon
icon: icon-192.png icon-512.png
icon-192.png: icon.svg
	$(CONVERT_SVG) -resize 192x192 $? $@
icon-512.png: icon.svg
	$(CONVERT_SVG) -resize 512x512 $? $@

.PHONY: go-list
go-list: go-list-all.avif go-list-all115.avif go-list-base.avif go-list-dotdotdot.avif go-list-dotdotdotdeps.avif go-list-dotdotdotdepstest.avif go-list-m.avif go-list-mall.avif 
go-list-all.png go-list-all.avif: go-list-all.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-all.avif go-list-all.png
go-list-all115.png go-list-all115.avif: go-list-all115.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-all115.avif go-list-all115.png
go-list-base.png go-list-base.avif: go-list-base.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-base.avif go-list-base.png
go-list-dotdotdot.png go-list-dotdotdot.avif: go-list-dotdotdot.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-dotdotdot.avif go-list-dotdotdot.png
go-list-dotdotdotdeps.png go-list-dotdotdotdeps.avif: go-list-dotdotdotdeps.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-dotdotdotdeps.avif go-list-dotdotdotdeps.png
go-list-dotdotdotdepstest.png go-list-dotdotdotdepstest.avif: go-list-dotdotdotdepstest.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-dotdotdotdepstest.avif go-list-dotdotdotdepstest.png
go-list-m.png go-list-m.avif: go-list-m.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-m.avif go-list-m.png
go-list-mall.png go-list-mall.avif: go-list-mall.svg
	$(CONVERT_SVG) -resize 1920x1080 $? -write go-list-mall.avif go-list-mall.png

.PHONY: http-timeouts
http-timeouts: http-timeouts.avif
http-timeouts.png http-timeouts.avif: http-timeouts.svg
	$(CONVERT_SVG) $? -write http-timeouts.avif http-timeouts.png

.PHONY: cf-rule-order-1
cf-rule-order-1: cf-rule-order-1.avif
cf-rule-order-1.avif: cf-rule-order-1.png
	convert $? -write cf-rule-order-1.avif

.PHONY: merged-analytics
merged-analytics: merged-analytics.avif
merged-analytics.avif: merged-analytics.png
	convert $? -write merged-analytics.avif

.PHONY: spotify-code
spotify-code: spotify-code.avif
spotify-code.avif: spotify-code.png
	convert $? -write spotify-code.avif

.PHONY: earbug-2022
earbug-2022: earbug-2022-artist.avif earbug-2022-consistency.avif earbug-2022-time.avif earbug-2022-track.avif
earbug-2022-artist.avif: earbug-2022-artist.png
	convert $? -write earbug-2022-artist.avif
earbug-2022-consistency.avif: earbug-2022-consistency.png
	convert $? -write earbug-2022-consistency.avif
earbug-2022-time.avif: earbug-2022-time.png
	convert $? -write earbug-2022-time.avif
earbug-2022-track.avif: earbug-2022-track.png
	convert $? -write earbug-2022-track.avif
