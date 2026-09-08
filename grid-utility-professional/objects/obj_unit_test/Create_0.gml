// RUNS A SERIES OF UNIT TESTS

global.test_pass = 0;
global.test_fail = 0;

/// @function				test_assert()
/// @description			Records a pass/fail result, logs it, and quits with an error code if failed.
/// @param {Bool}			_condition
/// @param {String}			_label

function test_assert(_condition, _label)
{
	if (_condition)
	{
	    global.test_pass++;
	    show_debug_message("[PASS] " + _label);
	}
	else
	{
	    global.test_fail++;
	    show_debug_message("[FAIL] " + _label);
	    show_debug_message("CRITICAL: Unit test failed. Terminating game.");
	    game_end(1); // Quit the game with a non-zero error status
	}
}

/// @function           test_expect_throw()
/// @description        Runs _callback and asserts that it throws.
/// @param {Function}   _callback
/// @param {String}     _label

function test_expect_throw(_callback, _label)
{
	var _threw = false;

	try
	{
	    _callback();
	}
	catch (_err)
	{
	    _threw = true;
	}

	test_assert(_threw, _label + " (expected throw)");
}

/// @function           test_expect_no_throw()
/// @description        Runs _callback and asserts that it does NOT throw. Returns whatever _callback returns.
/// @param {Function}   _callback
/// @param {String}     _label

function test_expect_no_throw(_callback, _label)
{
	var _threw  = false;
	var _result = undefined;

	try
	{
	    _result = _callback();
	}
	catch (_err)
	{
	    _threw = true;
	}

	test_assert(!_threw, _label + " (expected no throw)");
	return _result;
}


// =========================================================================
// 1. CONSTRUCTOR - TYPE CHECKS
// =========================================================================

// Feather disable GM1029
// Feather disable GM1041
// Feather disable GM1044

test_expect_throw(function()
{
	new obj_grid_controller.grid("32", 32, 64, 64, 12, 16);
}, "Constructor: x_offset as string");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, "32", 64, 64, 12, 16);
}, "Constructor: y_offset as string (not swapped for default)");

test_expect_throw(function()
{
	
	new obj_grid_controller.grid(32, 32, [64], 64, 12, 16); 
}, "Constructor: cell_width as array");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, "false", false);
}, "Constructor: label_text_type_row as string instead of bool");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, "c_white");
}, "Constructor: grid_colour as string");

// Feather enable GM1029
// Feather enable GM1041
// Feather enable GM1044

// =========================================================================
// 2. CONSTRUCTOR - WHOLE NUMBER CHECKS
// =========================================================================

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64.5, 64, 12, 16);
}, "Constructor: cell_width fractional (64.5)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64.25, 12, 16);
}, "Constructor: cell_height fractional (64.25)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 8.5, 16);
}, "Constructor: row_qty fractional (8.5)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 8.5);
}, "Constructor: column_qty fractional (8.5)");


// =========================================================================
// 3. CONSTRUCTOR - RANGE BOUNDARIES (cell_width / cell_height: 8-256)
// =========================================================================

var _grid_cw_min = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MIN, LIMIT_CELL_HEIGHT_MIN, 12, 16);
}, "Constructor: cell_width/height at exact MIN (8)");
if (!is_undefined(_grid_cw_min)) then _grid_cw_min.destroy();

var _grid_cw_max = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MAX, LIMIT_CELL_HEIGHT_MAX, 12, 16);
}, "Constructor: cell_width/height at exact MAX (256)");
if (!is_undefined(_grid_cw_max)) then _grid_cw_max.destroy();

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MIN - 1, 64, 12, 16);
}, "Constructor: cell_width one below MIN (7)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, LIMIT_CELL_WIDTH_MAX + 1, 64, 12, 16);
}, "Constructor: cell_width one above MAX (257)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, LIMIT_CELL_HEIGHT_MIN - 1, 12, 16);
}, "Constructor: cell_height one below MIN (7)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, LIMIT_CELL_HEIGHT_MAX + 1, 12, 16);
}, "Constructor: cell_height one above MAX (257)");


// =========================================================================
// 4. CONSTRUCTOR - RANGE BOUNDARIES (row_qty / column_qty: 1-128)
// =========================================================================

var _grid_rq_min = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MIN, LIMIT_COLUMN_QTY_MIN);
}, "Constructor: row_qty/column_qty at exact MIN (1)");
if (!is_undefined(_grid_rq_min)) then _grid_rq_min.destroy();

var _grid_rq_max = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MAX, LIMIT_COLUMN_QTY_MAX);
}, "Constructor: row_qty/column_qty at exact MAX (128)");
if (!is_undefined(_grid_rq_max)) then _grid_rq_max.destroy();

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MIN - 1, 16);
}, "Constructor: row_qty one below MIN (0)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MAX + 1, 16);
}, "Constructor: row_qty one above MAX (129)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, LIMIT_COLUMN_QTY_MIN - 1);
}, "Constructor: column_qty one below MIN (0)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, LIMIT_COLUMN_QTY_MAX + 1);
}, "Constructor: column_qty one above MAX (129)");


// =========================================================================
// 5. CONSTRUCTOR - COLOUR BOUNDARIES (0-16777215)
// =========================================================================

// Feather disable GM1029

var _grid_colour_min = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 0, 0, 0);
}, "Constructor: colours at exact MIN (0)");
if (!is_undefined(_grid_colour_min)) then _grid_colour_min.destroy();

var _grid_colour_max = test_expect_no_throw(function()
{
	return new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 16777215, 16777215, 16777215);
}, "Constructor: colours at exact MAX (16777215)");
if (!is_undefined(_grid_colour_max)) then _grid_colour_max.destroy();

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, -1);
}, "Constructor: grid_colour below MIN (-1)");

test_expect_throw(function()
{
	new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, false, false, 16777216);
}, "Constructor: grid_colour above MAX (16777216)");

// Feather enable GM1029


// =========================================================================
// 6. shift_x() / shift_y() - TYPE & WHOLE NUMBER GUARDS
// =========================================================================

// Feather disable GM1044

unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

test_expect_throw(function()
{
	unit_test.shift_x("1");
}, "shift_x: string argument");

test_expect_throw(function()
{
	unit_test.shift_x(1.5);
}, "shift_x: fractional argument");

test_expect_throw(function()
{
	unit_test.shift_y(undefined);
}, "shift_y: undefined argument");

test_expect_throw(function()
{
	unit_test.shift_y(0.1);
}, "shift_y: fractional argument");

// shift_x/shift_y should silently CLAMP large in-range-type values rather than throw

test_expect_no_throw(function()
{
	unit_test.shift_x(999999);
}, "shift_x: huge whole number is clamped, not thrown");

test_assert(unit_test.x_shift <= (1 + LIMIT_COLUMN_SHIFT_MAX - unit_test.column_qty), "shift_x: x_shift correctly clamped to upper bound");

test_expect_no_throw(function()
{
	unit_test.shift_y(-999999);
}, "shift_y: huge negative whole number is clamped, not thrown");

test_assert(unit_test.y_shift >= LIMIT_ROW_SHIFT_MIN, "shift_y: y_shift correctly clamped to lower bound");

// Feather enable GM1044

// =========================================================================
// 7. update_row() / update_column() - TYPE, WHOLE NUMBER & CLAMP BEHAVIOUR
// =========================================================================

test_expect_throw(function()
{
	unit_test.update_row("12");
}, "update_row: string argument");

test_expect_throw(function()
{
	unit_test.update_row(12.5);
}, "update_row: fractional argument");

test_expect_throw(function()
{
	unit_test.update_column(undefined);
}, "update_column: undefined argument");

test_expect_throw(function()
{
	unit_test.update_column(16.25);
}, "update_column: fractional argument");

// update_row/update_column clamp out-of-range whole numbers rather than throwing

test_expect_no_throw(function()
{
	unit_test.update_row(LIMIT_ROW_QTY_MAX + 50);
}, "update_row: value above MAX is clamped, not thrown");

test_assert(unit_test.row_qty == LIMIT_ROW_QTY_MAX, "update_row: row_qty clamped exactly to MAX");

test_expect_no_throw(function()
{
	unit_test.update_column(LIMIT_COLUMN_QTY_MIN - 50);
}, "update_column: value below MIN is clamped, not thrown");

test_assert(unit_test.column_qty == LIMIT_COLUMN_QTY_MIN, "update_column: column_qty clamped exactly to MIN");


// =========================================================================
// 8. get_x() / get_y() - CLAMPING AT SCREEN EXTREMES
// =========================================================================

// Feather disable GM1044

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

test_assert(unit_test.get_x(unit_test.x_offset - 99999) == 0, "get_x: far-left coordinate clamps to column 0");
test_assert(unit_test.get_x(unit_test.x_offset + 99999) == (unit_test.column_qty - 1), "get_x: far-right coordinate clamps to last column");

test_assert(unit_test.get_y(unit_test.y_offset - 99999) == 0, "get_y: far-above coordinate clamps to row 0");
test_assert(unit_test.get_y(unit_test.y_offset + 99999) == (unit_test.row_qty - 1), "get_y: far-below coordinate clamps to last row");

// Feather enable GM1044

// =========================================================================
// 9. zoom() - LIMIT BOUNDARIES
// =========================================================================

// Zoom out repeatedly until column/row qty would exceed LIMIT_*_QTY_MAX - values must stop growing, not overshoot.

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MAX, LIMIT_COLUMN_QTY_MAX);

test_expect_no_throw(function()
{
	unit_test.zoom(false); // zoom out - doubling would exceed MAX, so this call should be a no-op internally
}, "zoom(false): at MAX row/column qty does not throw");

test_assert(unit_test.row_qty == LIMIT_ROW_QTY_MAX, "zoom(false): row_qty unchanged when doubling would exceed MAX");
test_assert(unit_test.column_qty == LIMIT_COLUMN_QTY_MAX, "zoom(false): column_qty unchanged when doubling would exceed MAX");

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, LIMIT_ROW_QTY_MIN, LIMIT_COLUMN_QTY_MIN);

test_expect_no_throw(function()
{
	unit_test.zoom(true); // zoom in - halving would go below MIN, so this call should be a no-op internally
}, "zoom(true): at MIN row/column qty does not throw");

test_assert(unit_test.row_qty == LIMIT_ROW_QTY_MIN, "zoom(true): row_qty unchanged when halving would go below MIN");
test_assert(unit_test.column_qty == LIMIT_COLUMN_QTY_MIN, "zoom(true): column_qty unchanged when halving would go below MIN");

// zoom() sanitises its own argument - a non-bool should not crash, just skip the scale change

test_expect_no_throw(function()
{
	unit_test.zoom("true");
}, "zoom: non-bool argument does not throw (silently ignored)");


// =========================================================================
// 10. LIFECYCLE - guard_alive() / destroy()
// =========================================================================

// Feather disable GM1044

unit_test.destroy();
unit_test = new obj_grid_controller.grid(32, 32, 64, 64, 12, 16, true, false, c_white, c_white, c_red);

var _index_before_destroy = array_get_index(global.grid_list, unit_test);
test_assert(_index_before_destroy != -1, "destroy(): instance is present in global.grid_list before destroy");

unit_test.destroy();

var _index_after_destroy = array_get_index(global.grid_list, unit_test);
test_assert(_index_after_destroy == -1, "destroy(): instance removed from global.grid_list after destroy");

test_expect_throw(function()
{
	unit_test.draw();
}, "guard_alive: draw() after destroy() throws instead of crashing on freed vbuff");

test_expect_throw(function()
{
	unit_test.step();
}, "guard_alive: step() after destroy() throws instead of indexing undefined cell_data");

test_expect_throw(function()
{
	unit_test.shift_x(1);
}, "guard_alive: shift_x() after destroy() throws");

test_expect_throw(function()
{
	unit_test.update_row(10);
}, "guard_alive: update_row() after destroy() throws");

test_expect_throw(function()
{
	unit_test.get_x(0);
}, "guard_alive: get_x() after destroy() throws");

test_expect_no_throw(function()
{
	unit_test.destroy(); // second destroy() call must be a safe no-op, not an error
}, "destroy(): calling destroy() twice does not throw");

// Feather enable GM1044

// =========================================================================
// SUMMARY
// =========================================================================

show_debug_message("==============================================");
show_debug_message("UNIT TESTS COMPLETE: " + string(global.test_pass) + " passed, " + string(global.test_fail) + " failed.");
show_debug_message("==============================================");

// If execution reaches this point, all unit tests passed successfully
game_end(0);
