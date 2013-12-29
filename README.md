d-router
========

d-router is a fast routing library for D, modeled after the routing
semantics of Sinatra and Ruby on Rails.

`dub --build=unittest` to unittest

Routing
-------

`Router`, from the `d_router.router` module, is the main type exposed
by the d-router library. Pushing routes onto the router is done
through the `Router#push(string, callback)` method, where `callback` can be one of four types:

 - `void function()`
 - `void function(string[string] params)`
 - `void delegate()`
 - `void delegate(string[string] params)`

where `string[string]` is a hash of parameters matched in the route.

Routes can contain variables, denoted by beginning with a `:`, that
are then passed to the handler if it accepts a string[string] argument.

For instance, the route `/users/:name` will match `/users/dymk`, and
pass the handler the hash `["name": "dymk"]`.

Optional variables are also supported, by appending a '?' to the end
of the variable name.

For instance, the route `/users/:name?` will match both `/users` and `/users/dymk`,
passing an empty hash to the handler in the first case.

Defining Routes
---------------

`Route#push(string, callback)` pushes a new route to match on. The method takes a
string route pattern, and a callback to invoke when matched. The
method can be chained.

Example:

```d
import d_router.router;

void main()
{
	auto router = Router();

	/**
	 * Passing functions as handlers
	 */
	router.push("/foo/bar", {
		writeln("/foo/bar was called");
	});

	/**
	 * Passing functions as handlers, which take a
	 * string[string] containing the params hash
	 */
	router.push("/job/:name/:occupation", (params) {
		writefln("%s is a %s", params["name"], params["occupation"]);
	});

	/**
	 * Optional route parts
	 * This will match on /user, or /user/bob
	 */
	router.push("/user/:name?", (params) {

		auto name = "name" in params;
		if(name is null)
		{
			writeln("You didn't supply a name!");
		}
		else
		{
			writeln("Hello, ", *name);
		}

	});

	/**
	 * Delegate support
	 */
	int i = 0;
	router.push("/callme", {

		i++;
		writefln("Been called %d times", i);

	});

	/**
	 * Delegate with param support
	 */
	string[] seen_names;
	router.push("/addname/:name", (params) {

		seen_names ~= params["name"];
		writeln("Seen names: ", seen_names);

	});

	/**
	 * Push method chaining
	 */
	 router
	 .push("/chained/a", () { writeln("Matched a"); })
	 .push("/chained/b", () { writeln("Matched b"); })
	 .push("/chained/:o", (params) {
	 	writeln("Matched other: ", params["o"]);
	 });

```


Matching
--------

Matching on routes is simple, and accessed through the `Route#match`
method. `Route#match(string)` returns `true` if a match was found; else, `false`:

```d
void main()
{
	auto router = Router();

	router.push("/users/:name", (params) {
		writeln("Hello, ", params["name"]);
	});

	router.match("/foo/Dave"); // Prints `Hello, Dave` to stdout

	assert(router.match("/foo/bar") == true);
	assert(rotuer.match("/baz") == false);
}
```

Notes
-----

There are two implementations for determining if a route matches or not:
a `SplitterRoute`, and a `RegexRoute` class, both of which implement
the `Route` interface. `SplitterRoute` is approximatly twice as fast
for matching for all tests than `RegexRoute`, but it cannot handle
optional parameters.

`Router` will automatically determine which `Route` implementation
to use, prefering the `SplitterRoute` if the pattern contains no
optional parameters.
