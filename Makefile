debug:
	valac --pkg gstreamer-1.0 --pkg gtk+-3.0 --pkg gio-2.0 src/hello.vala

gst:
	valac --pkg gstreamer-1.0 --pkg gtk+-3.0 gsttest.vala
