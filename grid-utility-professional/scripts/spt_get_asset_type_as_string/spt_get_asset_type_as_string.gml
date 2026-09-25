/**
 * @function spt_get_asset_type_as_string()
 * @description Returns asset type as string.
 * @since v1.0.0.
 * @param	{String} _asset_name Name of asset in string form.
 * @returns {String} _string Asset type description.
 */

function spt_get_asset_type_as_string(_asset_name)
{
    var _type = asset_get_type(_asset_name);
    var _string = "unknown";
    
    switch (_type) 
    {
        case asset_sprite:
            _string = "sprite";
            break;
        
        case asset_sound:
            _string = "sound";
            break;
        
        case asset_object:
            _string = "object";
            break;
        
        case asset_room:
            _string = "room";
            break;
        
        case asset_script:
            _string = "script";
            break;
        
        case asset_font:
            _string = "font";
            break;
        
        case asset_path:
            _string = "path";
            break;
        
        case asset_timeline:
            _string = "timeline";
            break;
        
        case asset_shader:
            _string = "shader";
            break;
        
        case asset_animationcurve:
            _string = "animation curve";
            break;
        
        case asset_sequence:
            _string = "sequence";
            break;
        
        case asset_particlesystem:
            _string = "particle system";
            break;
        
        case asset_unknown:
        default:
            _string = "unknown";
            break;
    }
    
    return _string;
}