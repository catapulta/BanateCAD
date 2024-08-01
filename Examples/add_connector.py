import bpy
import bmesh
from mathutils import Vector

def slice_bottom(obj, height):
    print(f"Slicing bottom of {obj.name} at height {height}")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(obj.data)
    
    # Calculate the z-coordinate for slicing
    min_z = min(v.co.z for v in bm.verts)
    slice_z = min_z + height
    
    # Perform the bisection
    result = bmesh.ops.bisect_plane(
        bm,
        geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
        plane_co=(0, 0, slice_z),
        plane_no=(0, 0, 1),
        clear_inner=True  # Remove the bottom part
    )
    
    # Get the newly created edges from the bisection
    new_edges = [e for e in result['geom_cut'] if isinstance(e, bmesh.types.BMEdge)]
    
    # Create a new face from these edges
    if new_edges:
        bmesh.ops.contextual_create(bm, geom=new_edges)
    
    # Update the mesh
    bmesh.update_edit_mesh(obj.data)
    
    # Return to object mode
    bpy.ops.object.mode_set(mode='OBJECT')
    print("Slicing complete")

def move_to_xy_plane(obj):
    print(f"Moving {obj.name} to XY plane")
    
    # Get the world matrix of the object
    world_matrix = obj.matrix_world
    
    # Find the lowest z-coordinate in world space
    min_z = min((world_matrix @ v.co).z for v in obj.data.vertices)

    # Apply the translation
    obj.location.z -= min_z
    
    print(f"New Z location: {obj.location.z}")

def create_cylinder_cutout(obj, radius, height):
    print(f"Creating cylinder cutout for {obj.name}")
    print(f"Cutout radius: {radius}, height: {height}")
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height)
    cylinder = bpy.context.active_object
    # cylinder.location = obj.location.copy()
    # cylinder.location.z += height / 2
    # print(f"Cylinder location: {cylinder.location}")
    move_to_xy_plane(cylinder)
    cylinder.location.z -= 1.0
    
    bool_mod = obj.modifiers.new(name="Boolean", type='BOOLEAN')
    bool_mod.operation = 'DIFFERENCE'
    bool_mod.object = cylinder
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Boolean")
    bpy.data.objects.remove(cylinder, do_unlink=True)
    print("Cutout complete")

def center_on_bottom(obj_to_center, target_obj):
    print(f"Centering {obj_to_center.name} on bottom of {target_obj.name}")

    # 1. Compute target's max and min x, y, z
    target_min_x = min(v.co.x for v in target_obj.data.vertices)
    target_max_x = max(v.co.x for v in target_obj.data.vertices)
    target_min_y = min(v.co.y for v in target_obj.data.vertices)
    target_max_y = max(v.co.y for v in target_obj.data.vertices)
    target_min_z = min(v.co.z for v in target_obj.data.vertices)
    target_max_z = max(v.co.z for v in target_obj.data.vertices)

    # 2. Compute obj_to_center's max and min x, y, z
    center_min_x = min(v.co.x for v in obj_to_center.data.vertices)
    center_max_x = max(v.co.x for v in obj_to_center.data.vertices)
    center_min_y = min(v.co.y for v in obj_to_center.data.vertices)
    center_max_y = max(v.co.y for v in obj_to_center.data.vertices)
    center_min_z = min(v.co.z for v in obj_to_center.data.vertices)
    center_max_z = max(v.co.z for v in obj_to_center.data.vertices)

    # 3. Align the average x and y of both objects
    target_center_x = (target_min_x + target_max_x) / 2
    target_center_y = (target_min_y + target_max_y) / 2
    
    center_object_x = (center_max_x - center_min_x) / 2
    center_object_y = (center_max_y - center_min_y) / 2
    
    # Calculate the difference from current position
    delta_x = (target_center_x - center_object_x)
    delta_y = (target_center_y - center_object_y)

    # 4. Align the min z (in absolute terms)
    delta_z = target_min_z - center_min_z

    # Calculate the new location
    new_location = obj_to_center.location + Vector((delta_x, delta_y, delta_z))
    
    # Set the new location
    obj_to_center.location = new_location
    
    print(f"New location: {obj_to_center.location}")
    print(f"Target object bounds: X({target_min_x:.2f}, {target_max_x:.2f}), Y({target_min_y:.2f}, {target_max_y:.2f}), Z({target_min_z:.2f}, {target_max_z:.2f})")
    print(f"Centered object bounds: X({center_min_x:.2f}, {center_max_x:.2f}), Y({center_min_y:.2f}, {center_max_y:.2f}), Z({center_min_z:.2f}, {center_max_z:.2f})")
    print(f"Applied delta: X({delta_x:.2f}), Y({delta_y:.2f}), Z({delta_z:.2f})")

def scale_object(obj, scale_factor):
    print(f"Scaling {obj.name} by factor {scale_factor}")
    obj.scale *= scale_factor
    print(f"New scale: {obj.scale}")
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

def boolean_union(obj1, obj2):
    print(f"Performing boolean union of {obj1.name} and {obj2.name}")
    bool_mod = obj1.modifiers.new(name="Boolean", type='BOOLEAN')
    bool_mod.operation = 'UNION'
    bool_mod.object = obj2
    bpy.context.view_layer.objects.active = obj1
    bpy.ops.object.modifier_apply(modifier="Boolean")
    bpy.data.objects.remove(obj2, do_unlink=True)
    print("Union complete")

def load_stl_decimate(file_path, name, reduce_quality=False, reduction_ratio=0.5):
    if reduce_quality:
        try:
            obj = load_stl(file_path + f'_{reduction_ratio}', name)
        except:
            print("No cache found")
            obj = load_stl(file_path, name)
            print(f"Decimating {obj.name} to {reduction_ratio * 100}%")
            decimate_mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
            decimate_mod.ratio = reduction_ratio
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier="Decimate")
            print(f"Decimation complete. New vertex count: {len(obj.data.vertices)}")
            bpy.ops.object.select_all(action='DESELECT')
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.export_mesh.stl(filepath=file_path + f'_{reduction_ratio}', use_selection=True)
    else:
        obj = load_stl(file_path, name)
    
    return obj

def load_stl(file_path, name):
    print(f"Loading STL: {file_path}")
    bpy.ops.import_mesh.stl(filepath=file_path)
    obj = bpy.context.active_object
    obj.name = name
    print(f"Loaded object: {obj.name}")
    return obj

# Main script
print("Starting main script")

lamp = load_stl_decimate("/Users/aldo/BanateCAD/Examples/stl/earth_lamp_218mm-0.2n-Lblur.stl", "lamp", False, 0.2)
# slice_bottom(lamp, 8.42)
# slice_bottom(lamp, 11)
# slice_bottom(lamp, (11+8.42)/2)
move_to_xy_plane(lamp)

connector = load_stl("/Users/aldo/BanateCAD/Examples/stl/female_adapter-1.114x.stl", "connector")
scale_object(connector, 0.9546)  # scale to fit 218mm

# Create cylinder cutout for connector
connector_x = [v.co.x for v in connector.data.vertices]
connector_z = [v.co.z for v in lamp.data.vertices]
cutout_height = (max(connector_z) - min(connector_z)) / 2
cutout_radius = (max(connector_x) - min(connector_x)) / 2 - 0.3
create_cylinder_cutout(lamp, cutout_radius, cutout_height)
move_to_xy_plane(lamp)
move_to_xy_plane(connector)
# center_on_bottom(connector, lamp)

# Union lamp and modified connector
boolean_union(lamp, connector)

# Ensure the resulting object is selected
bpy.ops.object.select_all(action='DESELECT')
lamp.select_set(True)
bpy.context.view_layer.objects.active = lamp

output_path = "/Users/aldo/BanateCAD/Examples/stl/earth_lamp-218mm_adapter.stl"
print(f"Exporting result to: {output_path}")
bpy.ops.export_mesh.stl(filepath=output_path, use_selection=True)

print("Blender completed")
