@tool
class_name BTGPortalBody extends PortalBody

var mesh :
    set(value):
        size = value.get_aabb().size
