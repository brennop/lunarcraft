main:
	love .

web:
	mkdir -p build
	zip -9 -r build/lunar.love lib/ shaders/ src/ conf.lua main.lua tileset.png
	love.js -t "lunar" build/lunar.love build/lunar -c

clean:
	rm -rf build
