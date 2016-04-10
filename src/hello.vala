using Gtk;
using Gst;

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

    /* play button */
    var play_button = builder.get_object("play_button") as Button;
    var volume_button = builder.get_object("volume_button") as VolumeButton;

    /* Init image */
    var album_art_frame = builder.get_object("album_art_frame") as AspectFrame;
    var lossless_album_art = new Image.from_file("res/Lenna.png");

    lossless_album_art.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(400, 400, Gdk.InterpType.BILINEAR);


    var album_art_image = builder.get_object("album_art_image") as Image;
    album_art_image.set_from_pixbuf(lossless_album_art.pixbuf);




    /* Paned */
    var paned =  builder.get_object("paned1") as Paned;
    int oldW;
    int oldH;
    int oldP;
    oldP = paned.get_position();
    window.get_size(out oldW, out oldH);


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
        window.set_geometry_hints(null, hints, Gdk.WindowHints.MIN_SIZE);

        if (new_width < 12 || new_width > 180)
        {
            paned.set_position(oldP);
        }
        if (new_width > 180)
        {
            paned.set_position(180);
        }



        else if (oldP != new_width) {
        /*
            album_art_image.pixbuf =
            lossless_album_art.pixbuf.
                scale_simple((int)((oldW - new_width) *  400 / 1280), (int)((oldW - new_width) * 400 / 1280), Gdk.InterpType.BILINEAR);
                */
            oldP = new_width;
        }
    });


    /* placeholder pipeline */
    var pipeline = Gst.parse_launch("playbin uri=\"file:///home/ed/Programs/vala-music/haha.mp3\" volume=1");

    play_button.clicked.connect( () => {
        Gst.State state, pending;
        Gst.ClockTime timeout = 6000;
        pipeline.get_state(out state, out pending, timeout);
        if (state == State.PLAYING)
            pipeline.set_state (State.PAUSED);
        else
            pipeline.set_state (State.PLAYING);
    });

    //var volume = Gst.ElementFactory.make ("volume", "volume=0.1");
    /*
    volume_button.value_changed.connect( () => {
        string v = 0.1.to_string();
        pipeline.add("playbin volume=" + v);
        stderr.printf("VOL");
    });
*/

    window.show_all ();
    Gtk.main ();
    return 0;
}
