--------------------------------------------------------
-- Minetest :: Imagen Mod PRERELEASE v1.1 (imagen)
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
			drawing = { a = "#FFFFFFFF" },
			picture = { a = "#000000AA", b = "#00000022", x = "#FFFFFFFF" },
			graphic = { a = "#FFFFFFFF", b = "#00000044", x = "#444444FF" }
		} )[ depth ]
	end

	if depth == "picture" then
		formspec = sprintf( "box[%0.2f,%0.2f;%0.2f,%0.2f;%s]", horz, vert, width, height, palette.x )
	elseif depth == "graphic" then
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
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.a, y_map[ x ][ 1 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.b, y_map[ x ][ 2 ] ) )
			elseif depth == "graphic" then
		                formspec = formspec
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.a, y_map[ x ][ 1 ] ) )
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.b, y_map[ x ][ 2 ] ) )
			else
		                formspec = formspec
					.. sprintf( "label[%0.2f,%0.2f;%s]", h, v, minetest.colorize( palette.a, y_map[ x ] ) )
			end
		end
	end
	return formspec
end

--------------------------------------

local canvas_cache = { }
local S1,S1_=Stopwatch("load_image","s")
local S2,S2_=Stopwatch("rasterize","s")
local S3,S3_=Stopwatch("render_canvas","s")

local function show_image( name, param )
	if param == "" then
		canvas_cache = { }
		print( "canvas cache cleared" )
		return
	end

--	local filename = minetest.get_modpath( "imagen" ) .. "/images/" .. param .. ".ppm"
	local filename = "/var/www/html/uploads/" .. param .. ".ppm"
	if not canvas_cache[ filename ] then
		S1()
		local image = imagen.load_image( filename )
		S1_(true)

		if not image then
        		print( "Error reading " .. filename )
			return
		end

		S2()
		canvas_cache[ filename ] = imagen.rasterize( image, "picture" )
		S2_(true)
	end

	S3()
	local bpp = { drawing = 1, picture = 2, graphic = 2 }
	local canvas = canvas_cache[ filename ]

	local t1 = minetest.get_server_uptime( )
	local output_text = imagen.render_canvas( canvas, 0, 0 )
	local t2 = minetest.get_server_uptime( )

        local formspec = "size[10,8]"
                .. default.gui_bg
                .. default.gui_bg_img

		.. output_text

		.. string.format( "label[0.1,6.0;Filename = %s]", filename )
		.. string.format( "label[0.1,6.5;Canvas Area = %d x %d (%d bpp)]", canvas.width, canvas.height, bpp[ canvas.depth ] )
		.. string.format( "label[0.1,7.0;Output Size = %d bytes]", #output_text )
		.. string.format( "label[0.1,7.5;Render Time = %d ms]", t2 - t1 )

	minetest.create_form( nil, name, formspec, function ( ) end )
	S3_(true)
end

minetest.register_chatcommand( "img", {
        description = "Show a dynamically generated image given an input file.",
        func = show_image
})

minetest.register_chatcommand( "draw", {
        description = "Show a dynamically generated image with vector graphics.",
        func = function ( name, param )
		local image = imagen.init_image( 140, 140, { r = 0, g = 0, b = 0 } )

		imagen.draw_circle_solid( image, 45, 45, 40, { r = 255, g = 255, b = 255 } )
		imagen.draw_circle_outline( image, 80, 80, 50, { r = 255, g = 255, b = 255 } )
		imagen.draw_line( image, 60, 40, 135, 135, { r = 255, g = 255, b = 255 } )

		local output_text = imagen.render_canvas( imagen.rasterize( image, "drawing" ), 0.5, 0.5, { a = "#FFFF00FF" } )

	        local formspec = "size[4,4]"
        	        .. default.gui_bg
                	.. default.gui_bg_img
			.. output_text

			.. string.format( "label[0.1,7.0;Output Size = %d bytes]", #output_text )

		minetest.create_form( nil, name, formspec, function ( ) end )
	end
})
