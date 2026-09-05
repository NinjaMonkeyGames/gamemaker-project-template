// CONSTRUCTOR CLASS FOR GENERATING A 2D GRID

/// @description Generate 2D grid

global.grid_list = [];			 // Stores array of grid structs
global.grid_vformat = undefined; // Shared vertex format for all grid instances

// SOFT LIMITS

#macro  LIMIT_CELL_WIDTH_MIN 8
#macro  LIMIT_CELL_WIDTH_MAX 256
#macro  LIMIT_CELL_HEIGHT_MIN 8
#macro  LIMIT_CELL_HEIGHT_MAX 256

#macro  LIMIT_ROW_QTY_MIN 1
#macro  LIMIT_ROW_QTY_MAX 128
#macro  LIMIT_COLUMN_QTY_MIN 1
#macro  LIMIT_COLUMN_QTY_MAX 128

#macro LIMIT_ROW_SHIFT_MIN 0
#macro LIMIT_ROW_SHIFT_MAX 99
#macro LIMIT_COLUMN_SHIFT_MIN 0
#macro LIMIT_COLUMN_SHIFT_MAX 99

#macro LIMIT_X_SCALE_MIN 0.25
#macro LIMIT_Y_SCALE_MIN 0.25
#macro LIMIT_X_SCALE_MAX 2
#macro LIMIT_Y_SCALE_MAX 2

/// @description Singleton guard

if (variable_global_exists("controller") && instance_exists(global.controller))
{
	show_debug_message("A singleton pattern has been implimented for this object. Please don't call me again!");
    instance_destroy();	// Cleanup instance from memmory.
    exit;				// Stop the rest of Create from running
}

global.controller = id;

/**
 * @function grid()
 * @constructor
 * @description Generates a 2D grid based on parameters.
 * @since v0.1.0.
 * @param	{Real}				[_x_offset]					Offset draw position (horizontal).
 * @param	{Real}				[_y_offset]					Offset draw position (vertical).
 * @param	{Real}				[_cell_width]				Width of an individual grid cell in pixels or units.
 * @param	{Real}				[_cell_height]				Height of an individual grid cell in pixels or units.
 * @param	{Real}				[_row_qty]					Number of rows to draw.
 * @param	{Real}				[_column_qty]				Number of columns to draw.
 * @param	{Bool}				[_label_text_type_row]		Whether row labels are rendered as letters (true) or numbers (false).
 * @param	{Bool}				[_label_text_type_column]	Whether column labels are rendered as letters (true) or numbers (false).
 * @param	{Constant.Colour}	[_grid_colour]				Colour of the grid lines.
 * @param	{Constant.Colour}	[_text_colour]				Colour of unselected label text.
 * @param	{Constant.Colour}	[_text_colour_selected]		Colour of selected label text.
 * @param	{Array}				[_tile_data]				A struct containing tilemap data, indexed [row][column]. (sprite, index, angle, alpha).
 * @returns {Struct}										A new grid struct.
 */

function grid
(
_x_offset = 32, _y_offset = 32, 
_cell_width = 256, _cell_height = 256, 
_row_qty = 4, _column_qty = 6, 
_label_text_type_row = false, _label_text_type_column = false,
_grid_colour = c_white, _text_colour = c_white, _text_colour_selected = c_red,
_tile_data = undefined
)

constructor
{
	// CALCULATION VARIABLES
	
	is_destroyed = false; // Set true by destroy() - guarded methods check this before running.
	
	x_scale = 1;
	y_scale = 1;
		
	x_shift = 0;
	y_shift = 0;
	
	row_qty = _row_qty;
	column_qty = _column_qty;
		
	label_text_grid_gap_column = 6;
	label_text_grid_gap_row = 12;

	vbuff = -1;
	cache_cursor = window_get_cursor();

	// Vertex boundary cache (populated by set_grid), declared here for discoverability.

	grid_x1 = 0;
	grid_y1 = 0;
	grid_x2 = 0;
	grid_y2 = 0;

	/**
	 * @function validate_input()
	 * @description Validates arguments and throws on the first invalid one.
	 * @since v0.1.0.
	 * @param {Real}	[_x_offset]					Horizontal starting position (origin, top-left) of the grid.
	 * @param {Real}	[_y_offset]					Vertical starting position (origin, top-left) of the grid.
	 * @param {Real}	[_cell_width]				Width of an individual grid cell in pixels or units.
	 * @param {Real}	[_cell_height]				Height of an individual grid cell in pixels or units.
	 * @param {Real}	[_row_qty]					Number of rows.
	 * @param {Real}	[_column_qty]				Number of columns.
	 * @param {Bool}	[_label_text_type_row]		If row labels are rendered as letters (true) or numbers (false).
	 * @param {Bool}	[_label_text_type_column]	If column labels are rendered as letters (true) or numbers (false).
	 * @param {Real}	[_grid_colour]				Colour of the grid lines.
	 * @param {Real}	[_text_colour]				Default label text colour.
	 * @param {real}	[_text_colour_selected]		Label text colour when the row/column is under the cursor.
	 * @param {Array}	[_tile_data]				A struct containing tilemap data, indexed [row][column]. (sprite, index, angle, alpha).
	 */

	static validate_input = function
	(
	_x_offset, _y_offset, 
	_cell_width, _cell_height, 
	_row_qty, _column_qty, 
	_label_text_type_row, _label_text_type_column,
	_grid_colour, _text_colour, _text_colour_selected,
	_tile_data
	)
	{ 
		// CELL DATA CHECKS
		
		// Data type checks
		
		if !is_real(_x_offset)						then throw"X_OFFSET MUST BE A NUMBER";
		if !is_real(_y_offset)						then throw"Y_OFFSET MUST BE A NUMBER";
		
		if !is_real(_cell_width)					then throw"CELL_WIDTH MUST BE A NUMBER";
		if !is_real(_cell_height)					then throw"CELL_HEIGHT MUST BE A NUMBER";
		
		if !is_real(_row_qty)						then throw"ROW_QTY MUST BE A NUMBER";
		if !is_real(_column_qty)					then throw"COLUMN_QTY MUST BE A NUMBER";
		
		if !is_bool(_label_text_type_row)			then throw"LABEL TEXT TYPE ROW MUST BE A BOOLEAN";
		if !is_bool(_label_text_type_column)		then throw"LABEL TEXT TYPE COLUMN MUST BE A BOOLEAN";
		
		if !is_real(_grid_colour)					then throw"GRID COLOUR MUST BE A COLOUR";
		if !is_real(_text_colour)					then throw"TEXT COLOUR MUST BE A COLOUR";
		if !is_real(_text_colour_selected)			then throw"TEXT COLOUR SELECTED MUST BE A COLOUR";
		
		// Whole number checks
		
		if frac(_cell_width)	!= 0				then throw"_CELL_WIDTH MUST BE A WHOLE NUMBER";
		if frac(_cell_height)	!= 0				then throw"_CELL_HEIGHT MUST BE A WHOLE NUMBER";
		
		if frac(_row_qty)		!= 0				then throw"_ROW_QTY MUST BE A WHOLE NUMBER";
		if frac(_column_qty)	!= 0				then throw"_COLUMN_QTY MUST BE A WHOLE NUMBER";
		
		// Range checks
		
		if _cell_width				< LIMIT_CELL_WIDTH_MIN		||	_cell_width				>  LIMIT_CELL_WIDTH_MAX		then throw"_CELL_WIDTH";
		if _cell_height				< LIMIT_CELL_HEIGHT_MIN		||	 _cell_height			>  LIMIT_CELL_HEIGHT_MAX	then throw"_CELL_HEIGHT";
		
		if _row_qty					< LIMIT_ROW_QTY_MIN			||	_row_qty				>  LIMIT_ROW_QTY_MAX		then throw"_ROW_QTY";
		if _column_qty				< LIMIT_COLUMN_QTY_MIN		||	_column_qty				>  LIMIT_COLUMN_QTY_MAX		then throw"_COLUMN_QTY";
		
		if _grid_colour				< 0							||	_grid_colour			> 16777215					then throw"_GRID_COLOUR";
		if _text_colour				< 0							||	_text_colour			> 16777215					then throw"_TEXT_COLOUR";
		if _text_colour_selected	< 0							||	_text_colour_selected	> 16777215					then throw"_TEXT_COLOUR_SELECTED";
		
		// TILE DATA CHECKS
		
		if _tile_data != undefined
		{
			// Check the container is an array BEFORE indexing into it below.

			if !is_array(_tile_data) then throw"_TILE_DATA MUST BE AN ARRAY";

			// _tile_data is indexed [row][column], matching cell_data and draw().

			var _tile_data_row_qty = array_length(_tile_data);

			// Guard against an empty top-level array before indexing _tile_data[0] anywhere.

			if _tile_data_row_qty == 0 then throw"_TILE_DATA MUST NOT BE EMPTY";

			// The supplied grid must not be larger than the tile data backing it.

			if _row_qty > _tile_data_row_qty			then throw"BAD_GRID_SIZE, GRID MUST NOT HAVE MORE ROWS THAN TILE DATA ARRAY";
		
			/* 
			// Only validate the rows/columns the grid actually uses, not the full backing
			// array (which may be a much larger shared atlas). Column count is checked per
			// row rather than once from row 0, since rows are not guaranteed to be the same
			// length (a ragged array would otherwise throw GameMaker's own out-of-bounds
			// error here instead of a clean, custom one).
			*/

			for (var _row = 0; _row < _row_qty; ++_row) 
			{
				if !is_array(_tile_data[_row]) then throw string("BAD_TILE_DATA_ROW @ row " + string(_row) + " (not an array)");

				var _tile_data_column_qty = array_length(_tile_data[_row]);

				if _tile_data_column_qty == 0			then throw string("BAD_TILE_DATA_ROW @ row " + string(_row) + " (empty)");
				if _column_qty > _tile_data_column_qty	then throw string("BAD_GRID_SIZE, ROW " + string(_row) + " HAS FEWER COLUMNS THAN GRID REQUIRES");

				for (var _column = 0; _column < _column_qty; ++_column)
				{
					var _message = undefined;
				
					//  Datatype checks
				
						_message = string("BAD SPRITE @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if spt_get_asset_type_as_string(_tile_data[_row][_column].sprite) != "sprite" then throw(_message);
				
					_message = string("BAD_INDEX @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if !is_real(_tile_data[_row][_column].index) then throw(_message);
				
					_message = string("BAD_ANGLE @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if !is_real(_tile_data[_row][_column].angle) then throw(_message);
				
					_message = string("BAD_ALPHA @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if !is_real(_tile_data[_row][_column].alpha) then throw(_message);
				
					// Whole number checks
				
					_message = string("TILE INDEX MUST BE A WHOLE NUMBER @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if frac(_tile_data[_row][_column].index) != 0	then throw(_message);
				
					_message = string("TILE ANGLE MUST BE A WHOLE NUMBER @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if frac(_tile_data[_row][_column].angle) != 0	then throw(_message);
				
					// Range checks
				
					_message = string("BAD_INDEX @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if _tile_data[_row][_column].index < 0 || _tile_data[_row][_column].index > sprite_get_number(_tile_data[_row][_column].sprite) then throw(_message);
				
					_message = string("BAD_ANGLE @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if _tile_data[_row][_column].angle < 0 || _tile_data[_row][_column].angle > 359  then throw(_message);
				
					_message = string("BAD_ALPHA @ " + string("row ") + string(_row) + string(" column ") + string(_column));
					if _tile_data[_row][_column].alpha < 0 || _tile_data[_row][_column].alpha > 1  then throw(_message);
				}
			}
		}
	};
	
	// Validate raw arguments BEFORE anything (including clamp()) touches them.
	
	validate_input(_x_offset, _y_offset, _cell_width, _cell_height, _row_qty, _column_qty, _label_text_type_row, _label_text_type_column, _grid_colour, _text_colour, _text_colour_selected, _tile_data);

	// IMPORTED VARIABLES
	
	x_offset				= 	_x_offset;
	y_offset				= 	_y_offset;
	
	cell_width				= 	_cell_width;
	cell_height				= 	_cell_height;
	
	row_qty					= 	_row_qty;
	column_qty				= 	_column_qty;
	
	label_text_type_row		= 	_label_text_type_row;
	label_text_type_column	= 	_label_text_type_column;
	
	grid_colour				= 	_grid_colour;
	text_colour				= 	_text_colour;
	text_colour_selected	= 	_text_colour_selected;
	
	tile_data				= 	_tile_data;
		
	// Build the shared vertex format once, the first time any grid is created.
	
	if (is_undefined(global.grid_vformat))
	{
		vertex_format_begin();
		vertex_format_add_position();
		vertex_format_add_colour();
		
		global.grid_vformat = vertex_format_end();
	};

	/**
	 * @function guard_alive()
	 * @description Throws if this instance has already been destroyed. Single source of truth for the
	 * use-after-destroy check—call at the top of any method that reads cell_data/vbuff or mutates grid state.
	 * @since v0.1.0.
	 */


	static guard_alive = function()
	{
		if (is_destroyed) then throw"GRID INSTANCE HAS BEEN DESTROYED";
	};
    
	/**
	 * @function set_grid()
	 * @description Rebuilds the grid's vertex buffer and cell data from the current parameters.
	 * @since v0.1.0.
	 */


	static set_grid = function()
	{
		guard_alive();

		// Free any previous buffer before rebuilding, otherwise each call leaks a buffer.
		
		if (vbuff != -1)
		{
			vertex_delete_buffer(vbuff);
			vbuff = -1;
		};

		vbuff = vertex_create_buffer();
		vertex_begin(vbuff, global.grid_vformat);
		
		// Calculate vertex boundaries.
		
		grid_x1 = x_offset;
		grid_y1 = y_offset;
		grid_x2 = x_offset + (column_qty	* cell_width	* x_scale);
		grid_y2 = y_offset + (row_qty		* cell_height	* y_scale);

		// Horizontal lines.

		for (var _row = 0; _row <= row_qty; ++_row)
		{
			var _y = y_offset + (_row * cell_height * y_scale);

			vertex_position(vbuff, grid_x1, _y); vertex_colour(vbuff, grid_colour, 1);
			vertex_position(vbuff, grid_x2, _y); vertex_colour(vbuff, grid_colour, 1);
		};

		// Vertical lines.

		for (var _column = 0; _column <= column_qty; ++_column)
		{
			var _x = x_offset + (_column * cell_width * x_scale);

			vertex_position(vbuff, _x, grid_y1); vertex_colour(vbuff, grid_colour, 1);
			vertex_position(vbuff, _x, grid_y2); vertex_colour(vbuff, grid_colour, 1);
		};
		
		// Build grid cells.
		
		cell_data = array_create(0); // Initialise as array up fron to avoid feather warning.
		
		for (var _row = 0; _row < row_qty; ++_row) 
		{
		    var _is_top_edge = (_row == 0); // Top row also handles column headers below.

		    for (var _column = 0; _column < column_qty; ++_column) 
		    {
		        var _is_left_edge = (_column == 0); // Left column also handles row headers below.

		        // Calculate coordinates.
				
		        var _x_pos = x_offset + (_column	* cell_width	* x_scale);
		        var _y_pos = y_offset + (_row			* cell_height	* y_scale);

		        var _x1 = _x_pos;
		        var _y1 = _y_pos;
		        var _x2 = _x_pos + (cell_width		* x_scale);
		        var _y2 = _y_pos + (cell_height	* y_scale);

		        // Only build a row label (left edge) when this cell is in column 0.

		        var _row_string		= "";
		        var _label_row_x	= 0;
		        var _label_row_y	= 0;

		        if (_is_left_edge)
		        {
		            _row_string	= label_text_type_row ? convert_letters(_row + y_shift) : string(_row + y_shift);
		            _label_row_x	= (_x1 - string_width(_row_string)) - label_text_grid_gap_row;
		            _label_row_y	= _y1 + (cell_height * y_scale) / 2 - string_height(_row_string) / 2;
		        };

		        // Only build a column label (top edge) when this cell is in row 0.

		        var _column_string	= "";
		        var _label_column_x	= 0;
		        var _label_column_y	= 0;

		        if (_is_top_edge)
		        {
		            _column_string		= label_text_type_column ? convert_letters(_column + x_shift) : string(_column + x_shift);
		            _label_column_x	= _x1 + (cell_width * x_scale) / 2 - string_width(_column_string) / 2;
		            _label_column_y	= (_y1 - string_height(_column_string)) - label_text_grid_gap_column;
		        };
				
		        // Store cell data.
	
		        cell_data[_row][_column] =
		        {
		            x1 : _x1,
					y1 : _y1,
		            x2 : _x2,
		            y2 : _y2,
                
		            label_row_text : _row_string,
		            label_column_text : _column_string,
                
		            // Left label.
					
		            label_row_x : _label_row_x,
		            label_row_y : _label_row_y,

		            // Top label.
					
		            label_column_x : _label_column_x,
		            label_column_y : _label_column_y,
					
		            label_text_colour_row : text_colour,
		            label_text_colour_column : text_colour,
					
					// Label alpha
					
		            label_text_row_alpha  : 1,
		            label_text_column_alpha  : 1,
					
		            outline : true,
		        };
		    }
		}

		vertex_end(vbuff);
		vertex_freeze(vbuff); // Static geometry until the next set_grid() call, so freezing is safe and gives a GPU-side speed boost.
	}
	
	set_grid();
	
	/**
	 * @function get_x()
	 * @description Gets the column index under the given X coordinate.
	 * @since v0.1.0.
	 * @param {Real} [_x] X coordinate to check (mouse pointer by default).
	 * @returns {Real} Column index, clamped to a valid range.
	 * @self {struct.grid}
	 */

    
	static get_x = function(_x = mouse_x) 
	{
		guard_alive();
		return clamp(floor((_x - x_offset) / (cell_width * x_scale)), 0, floor(column_qty) - 1);
	}
	
	/**
	 * @function get_y()
	 * @description Gets the row index under the given Y coordinate.
	 * @since v0.1.0.
	 * @param {Real} [_y] Y coordinate to check (mouse pointer by default).
	 * @returns {Real} Row index, clamped to a valid range.
	 * @self {struct.grid}
	 */
	
	static get_y = function(_y = mouse_y) 
	{
		guard_alive();
		return clamp(floor((_y - y_offset) / (cell_height * y_scale)), 0, floor(row_qty) - 1);
	}
	
	/**
	 * @function shift_x()
	 * @description Shifts columns. (Negative values shift left.)
	 * @since v0.1.0.
	 * @param {Real} _value Amount to add to the current column shift.
	 * @self {struct.grid}
	 */

	
	static shift_x = function(_value) 
	{
		guard_alive();

		if !is_real(_value)		then throw"_VALUE MUST BE A NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		// max() guards against column_qty exceeding (1 + LIMIT_COLUMN_SHIFT_MAX), which would
		// otherwise invert clamp()'s min/max and let x_shift go negative.

		x_shift = clamp(x_shift + _value, LIMIT_COLUMN_SHIFT_MIN, max(LIMIT_COLUMN_SHIFT_MIN, 1 + LIMIT_COLUMN_SHIFT_MAX - column_qty));

		set_grid();
	}
	
	/**
	 * @function shift_y()
	 * @description Shifts rows. (Negative values shift up.)
	 * @since v0.1.0.
	 * @param {Real} _value Amount to add to the current row shift.
	 * @self {struct.grid}
	 */
	
	static shift_y = function(_value) 
	{
		guard_alive();

		if !is_real(_value)		then throw"_VALUE MUST BE A NUMBER";
		if frac(_value) != 0	then throw"_VALUE MUST BE A WHOLE NUMBER";

		// max() guards against row_qty exceeding (1 + LIMIT_ROW_SHIFT_MAX), which would
		// otherwise invert clamp()'s min/max and let y_shift go negative.

		y_shift = clamp(y_shift + _value, LIMIT_ROW_SHIFT_MIN, max(LIMIT_ROW_SHIFT_MIN, 1 + LIMIT_ROW_SHIFT_MAX - row_qty));
		
		set_grid();
	}
	
	/**
	 * @function set_coords()
	 * @description Highlights the row/column labels under the current mouse position.
	 * @since v0.1.0.
	 */

	static set_coords = function() 
	{
		guard_alive();

		var _select_x = get_x();
		var _select_y = get_y();

		for (var _row = 0; _row < row_qty; ++_row) 
		{
		    for (var _column = 0; _column < column_qty; ++_column) 
		    {
				cell_data[_row][_column].label_text_colour_row = (_row == _select_y) ? text_colour_selected : text_colour;
				cell_data[_row][_column].label_text_colour_column = (_column == _select_x) ? text_colour_selected : text_colour;
			}
		}
	}
	
	/**
	 * @function update_row()
	 * @description Changes the number of rows.
	 * @since v0.1.0.
	 * @param {Real} _value Number of rows in the new grid.
	 */

	static update_row = function(_value)
	{
		guard_alive();

		if !is_real(_value)		then throw"_VALUE MUST BE A NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		row_qty = clamp(_value, LIMIT_ROW_QTY_MIN, LIMIT_ROW_QTY_MAX);

		// max() guards against row_qty exceeding (1 + LIMIT_ROW_SHIFT_MAX), which would
		// otherwise invert clamp()'s min/max and let y_shift go negative.

		y_shift = clamp(y_shift, LIMIT_ROW_SHIFT_MIN, max(LIMIT_ROW_SHIFT_MIN, 1 + LIMIT_ROW_SHIFT_MAX - row_qty));
		
		set_grid();
	}
	
	/**
	 * @function update_column()
	 * @description Changes the number of columns.
	 * @since v0.1.0.
	 * @param {Real} _value Number of columns in the new grid.
	 */

	static update_column = function(_value)
	{
		guard_alive();

		if !is_real(_value)		then throw"_VALUE MUST BE A NUMBER";
		if frac(_value) != 0		then throw"_VALUE MUST BE A WHOLE NUMBER";

		column_qty = clamp(_value, LIMIT_COLUMN_QTY_MIN, LIMIT_COLUMN_QTY_MAX);

		// max() guards against column_qty exceeding (1 + LIMIT_COLUMN_SHIFT_MAX), which would
		// otherwise invert clamp()'s min/max and let x_shift go negative.

		x_shift = clamp(x_shift, LIMIT_COLUMN_SHIFT_MIN, max(LIMIT_COLUMN_SHIFT_MIN, 1 + LIMIT_COLUMN_SHIFT_MAX - column_qty));
	
		set_grid();
	}

	/**
	 * @function zoom()
	 * @description Zooms in/out while preserving the grid's total on-screen size.
	 * @since v0.1.0.
	 * @param {Bool} [_zoom_direction] True to zoom in, false to zoom out.
	 * @self {struct.grid}
	 */

	
	static zoom = function(_zoom_direction = true)
	{
		guard_alive();

		if is_bool(_zoom_direction) // Sanitise input to prevent an error.
		{
			if _zoom_direction == false
			{
				// Zooming out: halve the scale, double the row/column quantities.
				
				var _new_x_scale	= x_scale			/ 2;
				var _new_y_scale	= y_scale			/ 2;
				var _new_col			= column_qty	* 2;
				var _new_row		= row_qty			* 2;
            
				// Check if the new state respects the absolute limits.
				
				if (_new_x_scale >= LIMIT_X_SCALE_MIN && _new_x_scale <= LIMIT_X_SCALE_MAX &&
				    _new_col <= LIMIT_COLUMN_QTY_MAX && _new_row <= LIMIT_ROW_QTY_MAX)
				{
				    x_scale		= _new_x_scale;
				    y_scale		= _new_y_scale;
				    column_qty	= _new_col;
				    row_qty		= _new_row;
				}
			}
				else
			{
				// Zooming in: double the scale, halve the row/column quantities.
				
				var _new_x_scale	= x_scale			* 2;
				var _new_y_scale	= y_scale			* 2;
				var _new_col		= round(column_qty	/ 2);
				var _new_row		= round(row_qty		/ 2);
            
				// Check if the new state respects the absolute limits and won't hit zero cells.
				
				if (_new_x_scale >= LIMIT_X_SCALE_MIN && _new_x_scale <= LIMIT_X_SCALE_MAX &&
				    _new_col >= LIMIT_COLUMN_QTY_MIN && _new_row >= LIMIT_ROW_QTY_MIN)
				{
				    x_scale		= _new_x_scale;
				    y_scale		= _new_y_scale;
				    column_qty	= _new_col;
				    row_qty		= _new_row;
				}
			}
		}
       
		// Re-clamp both shifts against their respective (possibly changed) quantities.

		x_shift = clamp(x_shift, LIMIT_COLUMN_SHIFT_MIN, 1	+ LIMIT_COLUMN_SHIFT_MAX	- column_qty);
		y_shift = clamp(y_shift, LIMIT_ROW_SHIFT_MIN, 1		+ LIMIT_ROW_SHIFT_MAX		- row_qty);
		
		set_grid();	// Rebuild the grid geometry.
	}

	/**
	 * @function set_cursor()
	 * @description Sets the mouse pointer graphic depending on whether the cursor is over the grid.
	 * @since v0.1.0.
	 */

	static set_cursor = function() 
	{
		guard_alive();

		if point_in_rectangle(mouse_x, mouse_y, grid_x1, grid_y1, grid_x2, grid_y2)
		{
			// Remember whatever cursor was active immediately before we override it,
			// rather than whatever was active back at construction time - otherwise
			// this would restore a stale cursor if something else changes the global
			// cursor while this grid instance is alive.

			if window_get_cursor() != cr_handpoint then cache_cursor = window_get_cursor();

			window_set_cursor(cr_handpoint) ;
		}
			else
		{
			window_set_cursor(cache_cursor);
		}
	}

	/**
	 * @function convert_letters()
	 * @description Converts number to a letter the same way as you would see on an atlas or a spreadsheet.
	 * @since v0.1.0.
	 * @param {Real} _number The number to convert to a letter(s).
	 * @return {String} Return letter.
	 * @pure
	 */

	static convert_letters = function(_number)
	{
		if (!is_real(_number)) throw"PROVIDED PARAMETER IS NOT A REAL";
		if (_number < 0) throw"PROVIDED PARAMETER MUST NOT BE NEGATIVE";

		var _val = floor(_number);
		var _num = _val;
	
		if _number > 0 then _num ++;

		var _string = "";
	
		while (_num > 0)
		{
		    _num --; 
		    _string = chr((_num mod 26) + 65) + _string;
		    _num = _num div 26;
		}

		return (_string == "" ? "A" : _string);
	}

	/**
	 * @function step()
	 * @description Executes the step logic for this grid instance (input handling and state updates).
	 * @since v0.1.0.
	 */

	static step = function() 
	{
		with self
		{
			guard_alive();

			if mouse_wheel_down()
			{
				zoom(true);
			}
		
			if mouse_wheel_up()
			{
				zoom(false);
			}
		
			if keyboard_check_pressed(vk_left)		then shift_x(-1);
			if keyboard_check_pressed(vk_right)		then shift_x(1);
			if keyboard_check_pressed(vk_up)			then shift_y(-1);
			if keyboard_check_pressed(vk_down)		then shift_y(1);
		}
	}
	
	/**
	 * @function draw()
	 * @description Executes the draw logic for this grid instance (grid lines and labels).
	 * @since v0.1.0.
	 */

	static draw = function() 
	{
		with self
		{
			guard_alive();
		
			// Only inspect tile_data dimensions if tile data was actually supplied.

			var _tile_data_row_qty = 0;

			if tile_data != undefined
			{
				_tile_data_row_qty = array_length(tile_data);
			}
			
			for (var _row = 0; _row < row_qty; ++_row) 
			{
			    for (var _column = 0; _column < column_qty; ++_column) 
			    {
			        var _cache_cell_data = cell_data[_row][_column];

			        draw_text_ext_colour(_cache_cell_data.label_row_x, _cache_cell_data.label_row_y, _cache_cell_data.label_row_text, -1, -1, _cache_cell_data.label_text_colour_row, _cache_cell_data.label_text_colour_row, _cache_cell_data.label_text_colour_row, _cache_cell_data.label_text_colour_row, _cache_cell_data.label_text_row_alpha);
			        draw_text_ext_colour(_cache_cell_data.label_column_x, _cache_cell_data.label_column_y, _cache_cell_data.label_column_text, -1, -1, _cache_cell_data.label_text_colour_column, _cache_cell_data.label_text_colour_column, _cache_cell_data.label_text_colour_column, _cache_cell_data.label_text_colour_column, _cache_cell_data.label_text_column_alpha);
				
					if tile_data != undefined // Prevent error trying to draw tiles that were not imported.
					{
						var _tile_row = _row + y_shift;

						if _tile_row < _tile_data_row_qty // Prevents out of bounds error when trying to draw non existent array data.
						{
							// Column count is read per-row (not from row 0) since tile_data rows
							// are not guaranteed to be the same length - see validate_input().

							var _tile_data_column_qty = array_length(tile_data[_tile_row]);

							if _column + x_shift < _tile_data_column_qty
							{
								var _cache_tile_data = tile_data[_tile_row][_column + x_shift];
								draw_sprite_ext(_cache_tile_data.sprite, _cache_tile_data.index, _cache_cell_data.x1, _cache_cell_data.y1, x_scale, y_scale, 0, c_white, 1);
							}
						}
					}
				}
			}
		
			vertex_submit(vbuff, pr_linelist, -1); // Effectively draw grid.
		}
	}
	
	/**
	 * @function destroy()
	 * @description Removes this instance from the global grid list, frees GPU resources, and wipes all instance data.
	 * @since v0.1.0.
	 * @self {struct.grid}
	 */

	static destroy = function() 
	{
		if (is_destroyed) then return; // Already destroyed - safe no-op.

		// Find the current instance's index in the global array.
		
		var _index = array_get_index(global.grid_list, self);
    
		// Only remove if it actually exists in the array.
		
		if (_index != -1) { array_delete(global.grid_list, _index, 1); };

		// Free the vertex buffer - otherwise this leaks GPU memory every time a grid is destroyed.
		
		if (vbuff != -1)
		{
			vertex_delete_buffer(vbuff);
			vbuff = -1;
		}

		is_destroyed = true; // Set before the generic wipe below, since the wipe would otherwise erase it too.
			
		// feather disable GM1041
			
		var _names = variable_struct_get_names(self);

		for (var _i = 0; _i < array_length(_names); ++_i)
		{
			var _name = _names[_i];

			if (_name == "is_destroyed")						continue;
			if (is_method(variable_struct_get(self, _name)))	continue;

			variable_struct_set(self, _name, undefined);
		}
			
		// feather enable GM1041
	}
	
	array_push(global.grid_list, self); // Add this instance to the global grid list.

}