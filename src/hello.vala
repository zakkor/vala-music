using Gtk;
using Gst;

Gst.Pipeline pipeline;
Gst.Element source;
Gst.Element convert;
Gst.Element sink;

void pad_added_handler (Gst.Element src, Gst.Pad new_pad) {
		Gst.Pad sink_pad = convert.get_static_pad ("sink");
		stdout.printf ("Received new pad '%s' from '%s':\n", new_pad.name, src.name);

		// If our converter is already linked, we have nothing to do here:
		if (sink_pad.is_linked ()) {
			stdout.puts ("  We are already linked. Ignoring.\n");
			return ;
		}

		// Check the new pad's type:
		Gst.Caps new_pad_caps = new_pad.query_caps (null);
		weak Gst.Structure new_pad_struct = new_pad_caps.get_structure (0);
		string new_pad_type = new_pad_struct.get_name ();
		if (!new_pad_type.has_prefix ("audio/x-raw")) {
			stdout.printf ("  It has type '%s' which is not raw audio. Ignoring.\n", new_pad_type);
			return ;
		}

		// Attempt the link:
		Gst.PadLinkReturn ret = new_pad.link (sink_pad);
		if (ret != Gst.PadLinkReturn.OK) {
			stdout.printf ("  Type is '%s' but link failed.\n", new_pad_type);
		} else {
			stdout.printf ("  Link succeeded (type '%s').\n", new_pad_type);
		}
}

int main (string[] args) {
    Gst.init (ref args);
    Gtk.init (ref args);
    Gtk.Settings.get_default().gtk_enable_animations = true;

    var hints = Gdk.Geometry();


    var builder = new Builder ();
    /* Getting the glade file */
    builder.add_from_file ("src/ui/hello.ui");
    builder.connect_signals (null);

    /* Get and connect window signals */
    var window = builder.get_object ("window1") as Window;
    window.destroy.connect(Gtk.main_quit);

    /* search */
    var search_bar = builder.get_object("search_bar") as SearchEntry;

    /* drawing area*/
    var drawing_area = builder.get_object("drawing_area") as DrawingArea;

    /* play button */
    var pause_image = builder.get_object("pause_image") as Image;
    var play_image = builder.get_object("play_image") as Image;

    var play_button = builder.get_object("play_button") as Button;
    var previous_button = builder.get_object("previous_button") as Button;
    var next_button = builder.get_object("next_button") as Button;
    var volume_button = builder.get_object("volume_button") as VolumeButton;

    /* Init image */
    var album_art_frame = builder.get_object("album_art_frame") as AspectFrame;
    var lossless_album_art = new Image.from_file("res/queen.jpg");

    lossless_album_art.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(400, 400, Gdk.InterpType.BILINEAR);


    var album_art_image = builder.get_object("album_art_image") as Image;
    album_art_image.set_from_pixbuf(lossless_album_art.pixbuf);


    var listbox = builder.get_object("listbox1") as ListBox;


    /* Paned */
    var paned =  builder.get_object("paned1") as Paned;
    int oldW;
    int oldH;
    int oldP;
    oldP = paned.get_position();
    window.get_size(out oldW, out oldH);

    var max_paned_size = 180;


    /* Window resize */
    window.check_resize.connect( () => {
        int new_width;
        int new_height;
        window.get_size(out new_width, out new_height);

        //if (new_width + paned.get_position() >= 700)
        {
           // window.resize(1280, 720);
        }

        if ( (new_width != oldW ||
            new_height != oldH) ) {


                if (new_width != oldW)
                {

                /*
                    album_art_image.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(new_width * 400 / 1280, new_width * 400 / 1280, Gdk.InterpType.BILINEAR);
                        */
                    oldW = new_width;
                    oldH = new_height;
                }
                else if (new_height != oldH)
                {
                /*
                    album_art_image.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(new_height * 400 / 720, new_height * 400 / 720, Gdk.InterpType.BILINEAR);
                        */
                    oldW = new_width;

                    oldH = new_height;
                }




        }


    });

    /* Pane resize */
    paned.notify.connect( (s, p) => {
/*        int maxWidth = 0;
        foreach(Gtk.Widget element in listbox.get_children()) {

        }
        */
        int new_width = paned.get_position();

        hints.min_width = new_width + 600;
        //hints.max_height = 720;
        window.set_geometry_hints(null, hints, Gdk.WindowHints.MIN_SIZE);
        //window.set_geometry_hints(null, hints, Gdk.WindowHints.MAX_SIZE);

        if (new_width < 12 || new_width > max_paned_size)
        {
            paned.set_position(oldP);
        }
        if (new_width > max_paned_size)
        {
            paned.set_position(max_paned_size);
        }
        if (new_width < 12)
        {
            paned.set_position(12);
        }

        else if (oldP != new_width) {
            listbox.foreach ( (row) => {
                var lr = (ListBoxRow) row;
                lr.foreach ( (box) => {
                    box.set_opacity((double) ((new_width + (oldP /16)) * 1.0 / max_paned_size));
                });
            });
            oldP = new_width;
        }
    });

    //var volume = Gst.ElementFactory.make ("volume", "volume=0.1");
    /*
    volume_button.value_changed.connect( () => {
        string v = 0.1.to_string();
        my_pipe.add("playbin volume=" + v);
        stderr.printf("VOL");
    });
*/
    var my_pipe = Gst.parse_launch("playbin uri=\"file:///home/ed/Music/a.mp3");

    var current_row = -1;
    var current_song = "nope";



    /* dir */
    try {
        var directory = File.new_for_path ("/home/ed/Music");

        if (args.length > 1) {
            directory = File.new_for_commandline_arg (args[1]);
        }

        var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

        FileInfo file_info;
        var my_index = 0;
        while ((file_info = enumerator.next_file ()) != null) {
        //TODO
            var extension_pos = -1;
            for (var i = 0; i < file_info.get_name().length; i++) {
                if (file_info.get_name()[i] == '.')
                    extension_pos = i;
            }
            var extension = new StringBuilder();
            if (extension_pos != -1) {
                for (var i = extension_pos; i < file_info.get_name().length; i++) {
                    extension.append(file_info.get_name()[i].to_string());
                }
            }



            if (extension.str == ".mp3" ||
                extension.str == ".pls" ||
                extension.str == ".m3u" ||
                extension.str == ".wav") {
                my_index++;
                var new_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
                new_box.set_visible(true);

                //if (file_info.get_name().length * 9 > 700)
                //    max_paned_size = 700;
                //else
                if (file_info.get_name().length * 6 > max_paned_size)
                    max_paned_size = file_info.get_name().length * 6;

                var new_label = new Label(file_info.get_name());
                new_box.add(new_label);
                new_box.set_child_packing(new_label, false, false, 0, PackType.START);



                //var new_play_button = new Button();
                //var new_play_image = new Image.from_stock("gtk-media-play", IconSize.BUTTON);
                //new_play_image.set_visible(true);

/*
                new_play_button.set_label("");
                new_play_button.set_focus_on_click(false);
                new_play_button.set_image(new_play_image);
                new_play_button.set_relief(ReliefStyle.NONE);
                new_play_button.set_always_show_image(true);
                new_play_button.set_image_position (PositionType.RIGHT);
                new_play_button.set_alignment (1.0f, 0.5f);
                new_box.add(new_play_button);
*/
  //              new_box.set_child_packing(new_play_button, false, false, 0, PackType.END);

                listbox.add(new_box);

                // add signal
                /*
                new_play_button.clicked.connect( () => {
                    current_song = new_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    my_pipe.set_state (State.PAUSED);
                    my_pipe = Gst.parse_launch(play_string.str);
                    my_pipe.set_state(State.PLAYING);
                    play_button.set_image(pause_image);
                    current_row = my_index;
                    new_label.set_opacity(0.5);
                });
                */
            }
        }

    } catch (Error e) {
        stderr.printf ("Error: %s\n", e.message);
        return 1;
    }

    search_bar.search_changed.connect( () => {
        var first_result = -1;
        listbox.set_filter_func( (row) => {
            var show_row = false;
            if (row.get_index() >= 0 &&
                row.get_index() <= 1) {
                    return true;
                }
            row.foreach( (box) => {
                var cont = (Container) box;
                cont.foreach( (child) => {
                    if (child is Gtk.Label) {
                        var my_label = (Label) child;
                        if (my_label.label.down().contains(search_bar.get_text().down())) {
                            show_row = true;
                            if (first_result == -1) {
                                first_result = row.get_index();
                            }
                        }
                    }
                });
            });

            return show_row;
        });

       listbox.select_row(listbox.get_row_at_index(first_result));

/*
        var looking_for_sel = true;

        listbox.foreach( (row) => {
            var row_cast = (ListBoxRow) row;
            if (row_cast.get_visible() && looking_for_sel &&
                row_cast.get_index() >= 2) {
                stderr.printf(row_cast.get_index().to_string());
                listbox.select_row(row_cast);
                looking_for_sel = false;
            }
        });*/

    });

    /* set paned size to max */
    paned.set_position(max_paned_size);

    listbox.row_activated.connect( (row) => {
        current_row = row.get_index();
        row.foreach ( (box) => {
            Container con = (Container) box;

            var opaq = 0.5;

            con.foreach( (kid) => {
                kid.set_opacity(opaq);
                opaq+= 0.5;

                if (kid is Gtk.Label) {
                    var this_label = (Label) kid;
                    current_song = this_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    my_pipe.set_state (State.PAUSED);

                    play_button.set_image(pause_image);
                    my_pipe = Gst.parse_launch(play_string.str);

                    my_pipe.set_state(State.PLAYING);
                }
            });
        });
    });

    /* placeholder my_pipe */


    play_button.clicked.connect( () => {

        Gst.State state, pending;
        Gst.ClockTime timeout = 6000;
        my_pipe.get_state(out state, out pending, timeout);
        if (state == State.PLAYING) {
            my_pipe.set_state (State.PAUSED);
            //toggle_playing_button(true, play_button, play_image, pause_image);
            play_button.set_image(play_image);
        }
        else {
            my_pipe.set_state (State.PLAYING);
            play_button.set_image(pause_image);
            //toggle_playing_button(false, play_button, play_image, pause_image);
        }
    });

    previous_button.clicked.connect( () => {
        my_pipe.set_state (State.PAUSED);
        var row = listbox.get_row_at_index(current_row - 1);
        listbox.select_row(row);
        row.foreach ( (box) => {
            Container con = (Container) box;
            var opaq = 0.5;
            con.foreach( (kid) => {

                kid.set_opacity(opaq);
                opaq+= 0.5;

                if (kid is Gtk.Button)
                    stdout.printf("Is a Button.\n");
                if (kid is Gtk.Label) {
                    var this_label = (Label) kid;
                    current_song = this_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    my_pipe.set_state (State.PAUSED);
                    my_pipe = Gst.parse_launch(play_string.str);
                    my_pipe.set_state(State.PLAYING);
                    play_button.set_image(pause_image);
                    current_row--;
                }
            });
        });
    });

    next_button.clicked.connect( () => {
        my_pipe.set_state (State.PAUSED);
        my_pipe.set_state (State.PAUSED);
        var row = listbox.get_row_at_index(current_row + 1);
        listbox.select_row(row);
        row.foreach ( (box) => {
            Container con = (Container) box;
            var opaq = 0.5;
            con.foreach( (kid) => {

                kid.set_opacity(opaq);
                opaq+= 0.5;

                if (kid is Gtk.Button)
                    stdout.printf("Is a Button.\n");
                if (kid is Gtk.Label) {
                    var this_label = (Label) kid;
                    current_song = this_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    my_pipe.set_state (State.PAUSED);
                    my_pipe = Gst.parse_launch(play_string.str);
                    my_pipe.set_state(State.PLAYING);
                    play_button.set_image(pause_image);
                    current_row++;
                }
            });
        });
    });

    search_bar.activate.connect( () => {
        listbox.row_activated(listbox.get_selected_row());
        search_bar.set_text("");
        search_bar.move_focus(Gtk.DirectionType.DOWN);
        paned.set_position(0);
    });

    window.key_press_event.connect ( (event) => {
        if (!search_bar.has_focus) {
            if (event.type == Gdk.EventType.KEY_PRESS) {
                if (event.keyval == Gdk.Key.BackSpace) {
                    album_art_image.set_visible(false);
                    drawing_area.set_visible(true);
                }
                else if (event.keyval >= 'a' && event.keyval <= 'z') {
                    paned.set_position(max_paned_size);
                    search_bar.grab_focus();
                }
            }
        }
        return false;
    });

    drawing_area.draw.connect ((context) => {
        // Get necessary data:
        weak Gtk.StyleContext style_context = drawing_area.get_style_context ();
        int height = drawing_area.get_allocated_height ();
        int width = drawing_area.get_allocated_width ();
        Gdk.RGBA color = style_context.get_color (0);

        // Draw an arc:
        double xc = width / 2.0;
        double yc = height / 2.0;
        double radius = int.min (width, height) / 2.0;
        double angle1 = 0;
        double angle2 = 2*Math.PI;

        context.arc (xc, yc, radius, angle1, angle2);
        Gdk.cairo_set_source_rgba (context, color);
        context.fill ();
	    return true;
    });

	//var visbox = builder.get_object("visbox") as Box

	album_art_image.button_release_event.connect(() => {
	    stderr.printf("trolololol");
	    return false;
	});

    window.show_all ();
    Gtk.main ();
    return 0;
}
