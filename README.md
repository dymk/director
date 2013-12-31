Director
========

`director` is a fast routing library for D, modeled after the routing
semantics of Sinatra and Ruby on Rails.

`dub --build=unittest` to unittest

Routing
-------

`Router`, from the `director.router` module, is the main type exposed
by the director library. Pushing routes onto the router is done
through the `Router#push(string, callback)` method, where `callback` can be one of four types:

 - `void function()`
 - `void function(Params)`
 - `void delegate()`
 - `void delegate(Params)`

where `Params` is a hash of parameters matched in the route.

Routes can contain variables, denoted by beginning with a `:`, that
are then passed to the handler if it accepts a Params argument.
For instance, the route `/users/:name` will match `/users/dymk`, and
pass the handler a Params object containing `["name": "dymk"]`.

Optional variables are also supported, by appending a `?` to the end
of the variable name. For instance, the route `/users/:name?` will match both
`/users` and `/users/dymk`, passing an empty hash to the handler in the first case.

Defining Routes
---------------

`Route#push(string, callback)` pushes a new route to match on. The method takes a
string route pattern, and a callback to invoke when matched. The
method can be chained.

Example:

```d
import director.router;

void main()
{
	auto router = Router();

	/**
	 * Passing functions as handlers
	 */
	router.get("/foo/bar", {
		writeln("/foo/bar was called");
	});

	/**
	 * Passing functions as handlers, which take a
	 * string[string] containing the params hash
	 */
	router.get("/job/:name/:occupation", (params) {
		writefln("%s is a %s", params.name, params.occupation);
	});

	/**
	 * Optional route parts
	 * This will match on /user, or /user/bob
	 */
	router.get("/user/:name?", (params) {

		if(params.has("name"))
		{
			writeln("You didn't supply a name!");
		}
		else
		{
			writeln("Hello, ", params.name);
		}

	});

	/**
	 * Delegate support
	 */
	int i = 0;
	router.get("/callme", {

		i++;
		writefln("Been called %d times", i);

	});

	/**
	 * Delegate with param support
	 */
	string[] seen_names;
	router.get("/addname/:name", (params) {

		seen_names ~= params["name"];
		writeln("Seen names: ", seen_names);

	});

	/**
	 * Push method chaining
	 */
	router
	.get("/chained/a", () { writeln("Matched a"); })
	.get("/chained/b", () { writeln("Matched b"); })
	.get("/chained/:o", (params) {
		writeln("Matched other: ", params.o);
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
		writeln("Hello, ", params.name);
	});

	router.match("/foo/Dave"); // Prints `Hello, Dave` to stdout

	assert(router.match("/foo/bar") == true);
	assert(rotuer.match("/baz") == false);
}
```

The Params Object
-----------------

Params responds to `opDispatch`, and makes accessing variables matched
in the route easy.

 - `bool Params#has(string name)`: Returns true if `name` is in the params hash
 - `in` operator: Returns a pointer to the value in params (identical to `string in string[string]` )
 - `opDispatch(string name)()`: Returns the parameter variable for a given name, or raises if it's not found.
 - `opIndex(string name)`: Identical to `string[string]`'s `opIndex`; returns the parameter for that name.

```d
void main()
{
	auto r = Router();

	r.push("/:first/:opt", (params) {

		if(params.has("opt"))
		{
			writeln("First was: ", params.first);
			writeln("Opt was: ", params.opt);
		}
		else
		{
			writeln("First was: ", params["first"]);
		}

		// 'in' operator
		if("opt" in params)
		{
			writeln("Opt in params");
		}
	});
}
```

Notes
-----

There are two implementations for determining if a route matches or not:
a `SplitterRoute`, and a `RegexRoute` class, both of which implement
the `Route` interface. `SplitterRoute` is approximatly twice as fast
for matching for all tests than `RegexRoute`, but it cannot handle
optional parameters.

`Router` will determine which `Route` implementation to use, prefering
`SplitterRoute` if the route contains no optional parameters.
