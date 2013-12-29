module d_router.router;

private import
	std.stdio,
	std.array,
	std.regex,
	std.string,
	std.algorithm,
	std.typetuple,
	std.typetuple;

private import
	d_router.route,
	d_router.regex_route,
	d_router.splitter_route,
	d_router.part,
	d_router.params;

private
{
	alias CB_Delegate_Params = void delegate(Params);
	alias CB_Function_Params = void function(Params);
	alias CB_Delegate        = void delegate();
	alias CB_Function        = void function();

	enum isCallback(T) =
		is(T == CB_Function) || is(T == CB_Function_Params) ||
		is(T == CB_Delegate) || is(T == CB_Delegate_Params);

	struct RouteCallbackPair
	{
		Method method;
		Route route;
		union
		{
			CB_Delegate        d_callback;
			CB_Function        f_callback;
			CB_Delegate_Params dp_callback;
			CB_Function_Params fp_callback;
		}
		bool is_delegate;
		bool takes_params;

		this(CBType)(Method m, Route r, CBType cb)
		if(isCallback!CBType)
		{
			method = m;
			route = r;

			static if(is(CBType == delegate))
			{
				is_delegate = true;

				static if(is(CBType == CB_Delegate))
					d_callback = cb;
				else
				{
					takes_params = true;
					dp_callback = cb;
				}
			}
			else
			{
				is_delegate = false;

				static if(is(CBType == CB_Function))
					f_callback = cb;
				else
				{
					takes_params = true;
					fp_callback = cb;
				}
			}
		}
	}
}

enum Method
{
	Get    = 1,
	Post   = 2,
	Put    = 4,
	Delete = 8
}

struct Router
{
private:
	RouteCallbackPair[] routes;

	Route routeFor(string route_pattern)
	{
		if(Part.hasOptionalPart(route_pattern))
			return new RegexRoute(route_pattern);
		else
			return new SplitterRoute(route_pattern);
	}

	template BuildHttpMethods(string ident, alias method)
	{
		enum BuildHttpMethods =
		q{
			ref Router __ident(string pattern, CB_Function callback)
			{
				return define(__method, pattern, callback);
			}
			ref Router __ident(string pattern, CB_Function_Params callback)
			{
				return define(__method, pattern, callback);
			}
			ref Router __ident(string pattern, CB_Delegate callback)
			{
				return define(__method, pattern, callback);
			}
			ref Router __ident(string pattern, CB_Delegate_Params callback)
			{
				return define(__method, pattern, callback);
			}

			ref Router __ident(Route route, CB_Function callback)
			{
				return define(__method, route, callback);
			}
			ref Router __ident(Route route, CB_Function_Params callback)
			{
				return define(__method, route, callback);
			}
			ref Router __ident(Route route, CB_Delegate callback)
			{
				return define(__method, route, callback);
			}
			ref Router __ident(Route route, CB_Delegate_Params callback)
			{
				return define(__method, route, callback);
			}
		}
		.replace("__ident", ident)
		.replace("__method", method.stringof);
	}

	template SpecializedDefine(string cb_type)
	{
		enum SpecializedDefine =
		q{
			ref Router define(
				Method method,
				string route_pattern,
				%s callback)
			{
				return define(method, routeFor(route_pattern), callback);
			}
		}.format(cb_type);
	}

public:

	// DMD bugs mean mixin templates can't
	// be used to generate this, so do this hackery to
	// generate all the variants of get, post, put, and delete
	mixin(BuildHttpMethods!("get", Method.Get));
	mixin(BuildHttpMethods!("post", Method.Post));
	mixin(BuildHttpMethods!("put", Method.Put));
	mixin(BuildHttpMethods!("_delete", Method.Delete));

	// Parameter types are explicitly stated to allow type
	// inference on lambdas passed to get, post, define, etc
	// Order is important here: Prefer function type
	// callbacks above delegates in order to not
	// allocate a delegate's environment on each invocation
	mixin(SpecializedDefine!"CB_Function");
	mixin(SpecializedDefine!"CB_Function_Params");
	mixin(SpecializedDefine!"CB_Delegate");
	mixin(SpecializedDefine!"CB_Delegate_Params");

	ref Router define(CBType)(
		Method method,
		Route route,
		CBType callback)
	if(isCallback!CBType)
	{
		routes ~= RouteCallbackPair(method, route, callback);
		return this;
	}

	bool match(string pattern, Method method)
	{
		string[string] matched_params;
		foreach(ref pair; routes)
		{
			if(
				(pair.method & method) != 0 &&
				pair.route.matches(pattern, matched_params))
			{
				if(pair.is_delegate)
				{
					if(pair.takes_params)
						pair.dp_callback(Params(matched_params));
					else
						pair.d_callback();
				}
				else
				{
					if(pair.takes_params)
						pair.fp_callback(Params(matched_params));
					else
						pair.f_callback();
				}

				return true;
			}
		}

		return false;
	}
}

unittest
{
	auto r = Router();
	bool hit = false;

	r.get("/foo", () { hit = true; });
	r.get("/bar", () { hit = false; });

	assert(r.match("/foo", Method.Get));
	assert(hit);

	assert(!r.match("/asdf", Method.Get));
	assert(!r.match("/foo/bar", Method.Get));
	assert(!r.match("/bar/foo", Method.Get));
}

unittest
{
	auto r = Router();

	string hit;

	r
	.get("/a/a", { hit = "aye"; })
	.get("/a/b", { hit = "bee"; })
	.get("/a/:o", (p) { hit = p["o"]; });

	assert(!r.match("/a/", Method.Get));
	assert(!r.match("/a", Method.Get));

	assert(r.match("/a/a", Method.Get));
	assert(hit == "aye");

	assert(r.match("/a/b", Method.Get));
	assert(hit == "bee", "Hit was: " ~ hit);

	assert(r.match("/a/foo", Method.Get));
	assert(hit == "foo");

	assert(r.match("/a/z", Method.Get));
	assert(hit == "z");
}

unittest
{
	auto r = Router();

	with(Method)
	{
		r.define(Get|Post, "/a", {});
		assert(r.match("/a", Get));
		assert(r.match("/a", Post));
	}

	with(Method)
	{
		r.define(Get, "/b", {});
		assert(r.match("/b", Get|Post));
		assert(!r.match("/b", Post));
	}

}
