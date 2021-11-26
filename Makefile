check:
	luacheck src

run:
	love src

build: clean
	mkdir -p .build
	cd src && zip -9 -r ../.build/ultrabugs.love . -x "*.aseprite" -x "*.html"
	cd .build && npx love.js -c -t UltraBugs ultrabugs.love web
	cp src/assets/index.html .build/web/index.html
	rm -r .build/web/theme
	cd .build/web && zip -9 -r ../ultrabugs.zip . 

clean:
	rm -rf .build
	
.PHONY: check run build clean