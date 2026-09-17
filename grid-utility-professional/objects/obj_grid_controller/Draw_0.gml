/// @description Loops through draw code for each grid instance

var _list_size = array_length(global.grid_list);

for (var _i = 0; _i < _list_size; _i++)
{
    var _current_instance = global.grid_list[_i]; 
    _current_instance.draw();
}