(* $Id: gears.ml,v 1.1 2003/09/25 13:54:10 raffalli Exp $ *)

(*
 * 3-D gear wheels.    This program is in the public domain.
 *
 * Brian Paul
 * LablGL   version by Jacques Garrigue
 * LablGLUT version by Issac Trotts
 *)

open LablGL;;

let pi = acos (-1.)

(*
 * Draw a gear wheel.    You'll probably want to call this function when
 * building a display list since we do a lot of trig here.
 *
 * Input:    inner_radius - radius of hole at center
 *                 outer_radius - radius at center of teeth
 *                 width - width of gear
 *                 teeth - number of teeth
 *                 tooth_depth - depth of tooth
 *)
let gear ~inner ~outer ~width ~teeth ~tooth_depth =
    let r0 = inner
    and r1 = outer -. tooth_depth /. 2.0
    and r2 = outer +. tooth_depth /. 2.0 in

    let ta = 2.0 *. pi /. float teeth in
    let da = ta /. 4.0 in

    GlDraw.shade_model `flat;

    GlDraw.normal ~z:1.0 ();

    let vertex ~r ~z ?(s=0) i =
        let angle = float i *. ta +. float s *. da in
        GlDraw.vertex ~x:(r *. cos angle) ~y:(r *. sin angle) ~z ()
    in

    (* draw front face *)
    let z = width *. 0.5 in
    GlDraw.begins `quad_strip;
    for i=0 to teeth do
        vertex i ~r:r0 ~z;
        vertex i ~r:r1 ~z;
        vertex i ~r:r0 ~z;
        vertex i ~r:r1 ~z ~s:3;
    done;
    GlDraw.ends ();
    
    (* draw front sides of teeth *)
    GlDraw.begins `quads;
    for i=0 to teeth - 1 do
        vertex i ~r:r1 ~z;
        vertex i ~r:r2 ~s:1 ~z;
        vertex i ~r:r2 ~s:2 ~z;
        vertex i ~r:r1 ~s:3 ~z;
    done;
    GlDraw.ends ();

    GlDraw.normal ~z:(-1.0) ();

    (* draw back face *)
    let z = -. width *. 0.5 in
    GlDraw.begins `quad_strip;
    for i=0 to teeth do
        vertex i ~r:r1 ~z;
        vertex i ~r:r0 ~z;
        vertex i ~r:r1 ~s:3 ~z;
        vertex i ~r:r0 ~z;
    done;
    GlDraw.ends ();

    (* draw back sides of teeth *)
    GlDraw.begins `quads;
    for i=0 to teeth - 1 do
        vertex i ~r:r1 ~s:3 ~z;
        vertex i ~r:r2 ~s:2 ~z;
        vertex i ~r:r2 ~s:1 ~z;
        vertex i ~r:r1 ~z;
    done;
    GlDraw.ends ();

    (* draw outward faces of teeth *)
    let z = width *. 0.5 and z' = width *. (-0.5) in
    GlDraw.begins `quad_strip;
    for i=0 to teeth - 1 do
        let angle = float i *. ta in
        vertex i ~r:r1 ~z;
        vertex i ~r:r1 ~z:z';
        let u = r2 *. cos(angle+.da) -. r1 *. cos(angle)
        and v = r2 *. sin(angle+.da) -. r1 *. sin(angle) in
        GlDraw.normal ~x:v ~y:(-.u) ();
        vertex i ~r:r2 ~s:1 ~z;
        vertex i ~r:r2 ~s:1 ~z:z';
        GlDraw.normal ~x:(cos angle) ~y:(sin angle) ();
        vertex i ~r:r2 ~s:2 ~z;
        vertex i ~r:r2 ~s:2 ~z:z';
        let u = r1 *. cos(angle +. 3. *. da) -. r2 *. cos(angle +. 2. *. da)
        and v = r1 *. sin(angle +. 3. *. da) -. r2 *. sin(angle +. 2. *. da) in
        GlDraw.normal ~x:v ~y:(-.u) ();
        vertex i ~r:r1 ~s:3 ~z;
        vertex i ~r:r1 ~s:3 ~z:z';
        GlDraw.normal ~x:(cos angle) ~y:(sin angle) ();
    done;
    vertex 0 ~r:r1 ~z;
    vertex 0 ~r:r1 ~z:z';
    GlDraw.ends ();

    GlDraw.shade_model `smooth;

    (* draw inside radius cylinder *)
    GlDraw.begins `quad_strip;
    for i=0 to teeth do
        let angle = float i *. ta in
        GlDraw.normal ~x:(-. cos angle) ~y:(-. sin angle) ();
        vertex i ~r:r0 ~z:z';
        vertex i ~r:r0 ~z;
    done;
    GlDraw.ends ()

class view ~gear1 ~gear2 ~gear3 ~limit = object (self)
    val mutable view_rotx = 0.0
    val mutable view_roty = 0.0
    val mutable view_rotz = 0.0
    val mutable angle = 0.0
    val mutable count = 1

    method rotx a = view_rotx <- view_rotx +. a
    method roty a = view_roty <- view_roty +. a

    method draw =
        GlClear.clear [`color;`depth];

        GlMat.push ();
        GlMat.rotate ~angle:view_rotx ~x:1.0 ();
        GlMat.rotate ~angle:view_roty ~y:1.0 ();
        GlMat.rotate ~angle:view_rotz ~z:1.0 ();

        GlMat.push ();
        GlMat.translate ~x:(-3.0) ~y:(-2.0) ();
        GlMat.rotate ~angle:angle ~z:1.0 ();
        (* gear inner:1.0 outer:4.0 width:1.0 teeth:20 tooth_depth:0.7; *)
        GlList.call gear1;
        GlMat.pop ();

        GlMat.push ();
        GlMat.translate ~x:3.1 ~y:(-2.0) ();
        GlMat.rotate ~angle:(-2.0 *. angle -. 9.0) ~z:1.0 ();
        (* gear inner:0.5 outer:2.0 width:2.0 teeth:10 tooth_depth:0.7; *)
        GlList.call gear2;
        GlMat.pop ();

        GlMat.push ();
        GlMat.translate ~x:(-3.1) ~y:4.2 ();
        GlMat.rotate ~angle:(-2.0 *. angle -. 25.0) ~z:1.0 ();
        (* gear inner:1.3 outer:2.0 width:0.5 teeth:10 tooth_depth:0.7; *)
        GlList.call gear3;
        GlMat.pop ();

        GlMat.pop ();
        
        Glut.swapBuffers();

        count <- count + 1;
        if count =limit then exit 0

    method idle =
        angle <- angle +. 2.0;
        self#draw

    method reshape w h =
        GlDraw.viewport ~x:0 ~y:0 ~w:w ~h:h;
        GlMat.mode `projection;
        GlMat.load_identity ();
        let r = float w /. float h in
        let r' = 1. /. r in
        if (w>h) then
            GlMat.frustum ~x:(-. r,r) ~y:(-1.0,1.0) ~z:(5.0,60.0)
        else
            GlMat.frustum ~x:(-1.0,1.0) ~y:(-.r',r') ~z:(5.0,60.0);

        GlMat.mode `modelview;
        GlMat.load_identity();
        GlMat.translate ~z:(-40.0) ();
        GlClear.clear[`color;`depth]
end

let init () =
    let pos = 5.0, 5.0, 10.0, 0.0
    and red = 0.8, 0.1, 0.0, 1.0
    and green = 0.0, 0.8, 0.2, 1.0
    and blue = 0.2, 0.2, 1.0, 1.0 in

    GlLight.light ~num:0 (`position pos);
    List.iter Gl.enable
        [`cull_face;`lighting;`light0;`depth_test;`normalize];

    (* make the gears *)
    let make_gear ~inner ~outer ~width ~teeth ~color =
        let list = GlList.create `compile in
        GlLight.material ~face:`front (`ambient_and_diffuse color);
        gear ~inner ~outer ~width ~teeth ~tooth_depth:0.7;
        GlList.ends ();
        list
    in
    let gear1 = make_gear ~inner:1.0 ~outer:4.0 ~width:1.0 ~teeth:20 ~color:red
    and gear2 = make_gear ~inner:0.5 ~outer:2.0 ~width:2.0 ~teeth:10 ~color:green
    and gear3 = make_gear ~inner:1.3 ~outer:2.0 ~width:0.5 ~teeth:10 ~color:blue in

    (gear1, gear2, gear3)

let main () =
    ignore(Glut.init Sys.argv);
    Glut.initDisplayMode ~alpha:true ~double_buffer:true ~depth:true () ;
    Glut.initWindowSize ~w:300 ~h:300;
    ignore (Glut.createWindow ~title:"gears demo");
    let gear1, gear2, gear3 = init() in
    let view = new view ~gear1 ~gear2 ~gear3 ~limit:0 in
    let _reshape ~w ~h = 
        view#reshape w h 
    in 
    let _keyboard_callback ~key ~x ~y = 
        match (char_of_int key) with 'q' -> exit 0; | _ -> () 
    in
    let _special_key_callback ~key ~x ~y =
        (* let dummy = x+y in *)
        let delta = 5.0 in
        let redisp = ref true in 
        match key with 
            | Glut.KEY_LEFT  -> view#roty (-. delta) ; 
            | Glut.KEY_RIGHT -> view#roty delta ;
            | Glut.KEY_DOWN  -> view#rotx (-. delta) ; 
            | Glut.KEY_UP    -> view#rotx delta ;
            | _ -> begin 
                redisp := false; 
                (); 
            end;
        if !redisp then Glut.postRedisplay ();
    in

    Glut.keyboardFunc ~cb:_keyboard_callback ;
    Glut.reshapeFunc ~cb:_reshape ;
    Glut.displayFunc ~cb:(fun () -> view#draw) ;
    Glut.idleFunc(Some (fun () -> view#idle));
    Glut.specialFunc ~cb:_special_key_callback ;
    Glut.mainLoop();
    ;;

let _ = main ()

