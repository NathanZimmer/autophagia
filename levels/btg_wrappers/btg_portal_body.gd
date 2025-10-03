@tool
class_name BTGPortalBody extends PortalBody

var mesh: Mesh:
    set(value):
        size = value.get_aabb().size
