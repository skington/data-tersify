## TODO

Note that these were all things that I thought of at the time, so stuck them in
here. There is no guarantee that any of this will get done, or even that I 
still think it's a good idea.

# Better plugin handling

Let plugins say "ask me whether I want to deal with this object", e.g. as a
way of handling Role::DataObject.

Disable or enable plugins in real time.

See which plugins are available.

Configure plugins, e.g. "I never care about time zones"?

Tell plugins "I want you to tersify a bunch of different things", so they can
say e.g. "normally I'd say 00:00:00 isn't significant, but in this case it is".

# More automatic recognition of stuff

If there's no tersify plugin defined, see if the object has a to_string method.
(Although for HTTP::Message
objects you don't necessarily want to_string as (a) that might be huge also,
and (b) x will dump \cJ everywhere in your output.)

Check subclasses. (This might happen automatically for HTTP::Message tests.)

# Wrap other modules

If you say use Data::Tersify qw(Data::Printer) let it wrap p or np
so it's tersified via Data::Tersify instead. Similarly for other dumping
classes.

i.e. capture the output *and* select STDOUT and STDERR, and see what the
function did, then stop selecting STDOUT and STDERR and reproduce the
captured behaviour.

# Detect whether it *should* tersify.

Look at the size of the window and the size of the output and determine
whether it makes sense to tersify - e.g. if you're wrapping a function that
would print [0..10] as [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] all on one line,
that's not long; if it would print them on one line each, it's too long.

Look at where we *are* in the window to determine whether we need to tersify.
If the window wouldn't scroll, it's fine.

Because we shouldn't account for ANSI control characters, possibly try
printing out stuff, stop as soon as we get to the point where we'd scroll,
then erase all the printed stuff and print terse stuff instead.