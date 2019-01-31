--------------------------------------------------------
-- Minetest :: Imagen Mod v1.1 PRERELEASE (imagen)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2019, Leslie Ellen Krause
--
-- ./games/just_test_tribute/mods/imagen/init.lua
--------------------------------------------------------

imagen = { }

--------------------------------------
-- imagen.load_image( )
--------------------------------------

imagen.load_image = function ( filename )
        local fp = io.open( filename, "rb" )

        if fp == nil then return nil end
        local line = fp:read( "*line" )
        if line ~= "P6" then return nil end

        repeat
                line = fp:read( "*line" )
        until string.find( line, "#" ) == nil

        local data = { }
        local size_x, size_y

        size_x = string.match( line, "%d+" )
        size_y = string.match( line, "%s%d+" )

	line = fp:read( "*line" )
        if tonumber( line ) ~= 255 then return nil end

	for i = 1, size_y do
		data[ i ] = { }
	end

	for y = 1, size_y do
		for x = 1, size_x do
			-- tricolor values
			local r = string.byte( fp:read( 1 ) )
			local g = string.byte( fp:read( 1 ) )
			local b = string.byte( fp:read( 1 ) )
			-- grayscale value
			local k = ( r + g + b ) / 3

			data[ y ][ x ] = { r = r, g = g, b = b, k = k }

--			io.write( k < 64 and " " or k < 128 and ":" or "#" )
		end
--		io.write( "\n" )
	end
	fp:close( )

	return { data = data, size_y = size_y, size_x = size_x }
end

--------------------------------------
-- imagen.init_image( )
--------------------------------------

imagen.init_image = function ( size_x, size_y, color )
	local data = { }
	for i = 1, size_y do
		data[ i ] = { }
	end

	local c = { r = color.r, g = color.g, b = color.b, k = ( color.r + color.g + color.b ) / 3 }
	for y = 1, size_y do
		for x = 1, size_x do
			data[ y ][ x ] = c
		end
	end

	return { data = data, size_y = size_y, size_x = size_x }
end

--------------------------------------

imagen.draw_circle_solid = function ( image, x, y, r, color )
	local c = { r = color.r, g = color.g, b = color.b, k = ( color.r + color.g + color.b ) / 3 }
	for i = x - r, x + r do
		for j = y - r, y + r do
			if ( i - x ) * ( i - x ) + ( j - y ) * ( j - y ) <= r * r then
				image.data[ i ][ j ] = c
			end
		end
	end
end

imagen.draw_circle_outline = function ( image, x, y, r, color )
	local i = 0
	local j = r
	local d = 3 - 2 * r
	local c = { r = color.r, g = color.g, b = color.b, k = ( color.r + color.g + color.b ) / 3 }

	local function draw_circle( )
		image.data[ y + j ][ x + i ] = c
		image.data[ y + j ][ x - i ] = c
		image.data[ y - j ][ x + i ] = c
		image.data[ y - j ][ x - i ] = c
		image.data[ y + i ][ x + j ] = c
		image.data[ y + i ][ x - j ] = c
		image.data[ y - i ][ x + j ] = c
		image.data[ y - i ][ x - j ] = c
	end

	draw_circle( )
	while j >= i do
		i = i + 1
		if d > 0 then
			j = j - 1
			d = d + 4 * ( i - j ) + 10
		else
			d = d + 4 * i + 6
		end
		draw_circle( )
	end
end

imagen.draw_line = function ( image, x1, y1, x2, y2, color )
	local dx = x2 - x1
	local dy = y2 - y1
	local d = dy - dx / 2
	local x = x1
	local y = y1
	local c = { r = color.r, g = color.g, b = color.b, k = ( color.r + color.g + color.b ) / 3 }

	while x < x2 do
		x = x + 1
		if d < 0 then
			d = d + dy
		else
			d = d + dy - dx
			y = y + 1
		end
		image.data[ y ][ x ] = c
	end
end

--------------------------------------
-- imagen.rasterize( )
--------------------------------------

imagen.rasterize = function ( image, depth, gamma )
	local map = { }
	local data = image.data
	local iy_max = 19
	local ix_max = 4

	if not depth then
		depth = "drawing"
	end
	if not gamma then
		gamma = ( {
			drawing = { 128 },
			picture = { 48, 64, 128 },
			graphic = { 48, 64, 128 }
		} )[ depth ]
	end

        for y = 1, image.size_y do
		local iy = ( y - 1 ) % iy_max + 1

		if not map[ iy ] then map[ iy ] = { } end

		local y_map = map[ iy ]
                for x = 1, image.size_x do
			local ix = ( x - 1 ) % ix_max + 1
			local k = data[ y ][ x ].k

			if not y_map[ ix ] then
				y_map[ ix ] = depth == "drawing" and "" or { "", "" }
			end

			if depth == "drawing" then
				local bit = k < gamma[ 1 ] and " " or "."
				y_map[ ix ] = y_map[ ix ] .. bit
			elseif depth == "picture" then
				local bit1 = k < gamma[ 2 ] and "." or " "
				local bit2 = k < gamma[ 1 ] and "." or k < gamma[ 2 ] and " " or k < gamma[ 3 ] and "." or " "
				y_map[ ix ][ 1 ] = y_map[ ix ][ 1 ] .. bit1
				y_map[ ix ][ 2 ] = y_map[ ix ][ 2 ] .. bit2
			elseif depth == "graphic" then
				local bit1 = k < gamma[ 2 ] and " " or "."
				local bit2 = k < gamma[ 1 ] and "." or k < gamma[ 2 ] and " " or k < gamma[ 3 ] and "." or " "
				y_map[ ix ][ 1 ] = y_map[ ix ][ 1 ] .. bit1
				y_map[ ix ][ 2 ] = y_map[ ix ][ 2 ] .. bit2
			end
		end
		if depth == "drawing" then
			for ix = 1, ix_max do
				y_map[ ix ] = y_map[ ix ] .. "\n"
			end
		else
			for ix = 1, ix_max do
				y_map[ ix ][ 1 ] = y_map[ ix ][ 1 ] .. "\n"
				y_map[ ix ][ 2 ] = y_map[ ix ][ 2 ] .. "\n"
			end
		end
	end

	-- TODO: support bitmaps smaller than ix_max x iy_max dimensions!

        return { map = map, depth = depth, iy_max = iy_max, ix_max = ix_max, width = image.size_x / 50, height = image.size_y / 48 }
end

imagen.rasterize_pixmap = function ( image, gamma )
	local map = { }
	local data = image.data
	local iy_max = 19
	local ix_max = 4

	if not depth then
		depth = "drawing"
	end
	if not gamma then
		gamma = { 48, 64, 128 }
	end

        for y = 1, image.size_y do
		local iy = ( y - 1 ) % iy_max + 1

		if not map[ iy ] then map[ iy ] = { } end

		local y_map = map[ iy ]
                for x = 1, image.size_x do
			local ix = ( x - 1 ) % ix_max + 1
			local r = data[ y ][ x ].r
			local g = data[ y ][ x ].g
			local b = data[ y ][ x ].b
			local k = data[ y ][ x ].k

			if not y_map[ ix ] then
				y_map[ ix ] = { "", "", "", "" }
			end

			local bitR = r < 64 and " " or "."
			local bitG = g < 64 and " " or "."
			local bitB = b < 64 and " " or "."
			local bitK = k < 32 and "." or k < 64 and " " or k < 128 and "." or " "
			y_map[ ix ][ 1 ] = y_map[ ix ][ 1 ] .. bitR
			y_map[ ix ][ 2 ] = y_map[ ix ][ 2 ] .. bitG
			y_map[ ix ][ 3 ] = y_map[ ix ][ 3 ] .. bitB
			y_map[ ix ][ 4 ] = y_map[ ix ][ 4 ] .. bitK
		end
		for ix = 1, ix_max do
			y_map[ ix ][ 1 ] = y_map[ ix ][ 1 ] .. "\n"
			y_map[ ix ][ 2 ] = y_map[ ix ][ 2 ] .. "\n"
			y_map[ ix ][ 3 ] = y_map[ ix ][ 3 ] .. "\n"
			y_map[ ix ][ 4 ] = y_map[ ix ][ 4 ] .. "\n"
		end
	end

	-- TODO: support bitmaps smaller than ix_max x iy_max dimensions!

        return { map = map, depth = "artwork", iy_max = iy_max, ix_max = ix_max, width = image.size_x / 50, height = image.size_y / 48 }
end

--------------------------------------
-- imagen.render_canvas( )
--------------------------------------

imagen.render_canvas = function ( canvas, horz, vert, palette )
	local formspec = ""
	local map = canvas.map
	local iy_max = canvas.iy_max
	local ix_max = canvas.ix_max
	local depth = canvas.depth
	local width = canvas.width
	local height = canvas.height
	local sprintf = string.format

	if not palette then
		palette = ( {
			drawing = { m = "#FFFFFFFF" },
			picture = { m = "#000000AA", k = "#00000022", x = "#FFFFFFFF" },
			graphic = { m = "#FFFFFFFF", k = "#00000044", x = "#444444FF" },
			artwork = { r = "#FFAAAA77", g = "#AAFFAA77", b = "#AAAAFF77", k = "#00000088", x = "#444444FF" },
		} )[ depth ]
	end

	if depth ~= "drawing" then
		formspec = sprintf( "box[%0.2f,%0.2f;%0.2f,%0.2f;%s]", horz, vert, width, height, palette.x )
	end

        for y = 1, iy_max do
		local v = vert + ( y - 1 ) * 0.021 - 0.30
--		local v = vert + ( y - 1 ) * 0.02 - 0.30
		local y_map = map[ y ]

		for x = 1, ix_max do
			local h = horz + ( x - 1 ) * 0.02 - 0.04
--			local h = horz + ( x - 1 ) * 0.017 - 0.04

			if depth == "picture" then
		                formspec = formspec
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.m, y_map[ x ][ 1 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.k, y_map[ x ][ 2 ] ) )
			elseif depth == "graphic" then
		                formspec = formspec
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.m, y_map[ x ][ 1 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.k, y_map[ x ][ 2 ] ) )
			elseif depth == "artwork" then
		                formspec = formspec
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.r, y_map[ x ][ 1 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.g, y_map[ x ][ 2 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.b, y_map[ x ][ 3 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.k, y_map[ x ][ 4 ] ) )
			else
		                formspec = formspec
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.m, y_map[ x ] ) )
			end
		end
	end
	return formspec
end
