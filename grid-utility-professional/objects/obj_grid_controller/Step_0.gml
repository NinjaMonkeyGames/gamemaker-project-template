/// @description Loops through step code for each grid instance

var _list_size = array_length(global.grid_list);

for (var i = 0; i < _list_size; i++)
{
    var _current_instance = global.grid_list[i];
    _current_instance.step();
}