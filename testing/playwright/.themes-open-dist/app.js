(() => {
  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Bind/foreign.js
  var arrayBind = typeof Array.prototype.flatMap === "function" ? function(arr) {
    return function(f) {
      return arr.flatMap(f);
    };
  } : function(arr) {
    return function(f) {
      var result = [];
      var l = arr.length;
      for (var i2 = 0; i2 < l; i2++) {
        var xs = f(arr[i2]);
        var k = xs.length;
        for (var j = 0; j < k; j++) {
          result.push(xs[j]);
        }
      }
      return result;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Apply/foreign.js
  var arrayApply = function(fs) {
    return function(xs) {
      var l = fs.length;
      var k = xs.length;
      var result = new Array(l * k);
      var n = 0;
      for (var i2 = 0; i2 < l; i2++) {
        var f = fs[i2];
        for (var j = 0; j < k; j++) {
          result[n++] = f(xs[j]);
        }
      }
      return result;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Semigroupoid/index.js
  var semigroupoidFn = {
    compose: function(f) {
      return function(g) {
        return function(x) {
          return f(g(x));
        };
      };
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Category/index.js
  var identity = function(dict) {
    return dict.identity;
  };
  var categoryFn = {
    identity: function(x) {
      return x;
    },
    Semigroupoid0: function() {
      return semigroupoidFn;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Boolean/index.js
  var otherwise = true;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Function/index.js
  var flip = function(f) {
    return function(b2) {
      return function(a2) {
        return f(a2)(b2);
      };
    };
  };
  var $$const = function(a2) {
    return function(v) {
      return a2;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Functor/foreign.js
  var arrayMap = function(f) {
    return function(arr) {
      var l = arr.length;
      var result = new Array(l);
      for (var i2 = 0; i2 < l; i2++) {
        result[i2] = f(arr[i2]);
      }
      return result;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Unit/foreign.js
  var unit = void 0;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Type.Proxy/index.js
  var $$Proxy = /* @__PURE__ */ function() {
    function $$Proxy2() {
    }
    ;
    $$Proxy2.value = new $$Proxy2();
    return $$Proxy2;
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Functor/index.js
  var map = function(dict) {
    return dict.map;
  };
  var mapFlipped = function(dictFunctor) {
    var map117 = map(dictFunctor);
    return function(fa) {
      return function(f) {
        return map117(f)(fa);
      };
    };
  };
  var $$void = function(dictFunctor) {
    return map(dictFunctor)($$const(unit));
  };
  var voidLeft = function(dictFunctor) {
    var map117 = map(dictFunctor);
    return function(f) {
      return function(x) {
        return map117($$const(x))(f);
      };
    };
  };
  var voidRight = function(dictFunctor) {
    var map117 = map(dictFunctor);
    return function(x) {
      return map117($$const(x));
    };
  };
  var functorArray = {
    map: arrayMap
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Apply/index.js
  var identity2 = /* @__PURE__ */ identity(categoryFn);
  var applyArray = {
    apply: arrayApply,
    Functor0: function() {
      return functorArray;
    }
  };
  var apply = function(dict) {
    return dict.apply;
  };
  var applySecond = function(dictApply) {
    var apply1 = apply(dictApply);
    var map36 = map(dictApply.Functor0());
    return function(a2) {
      return function(b2) {
        return apply1(map36($$const(identity2))(a2))(b2);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Applicative/index.js
  var pure = function(dict) {
    return dict.pure;
  };
  var unless = function(dictApplicative) {
    var pure110 = pure(dictApplicative);
    return function(v) {
      return function(v1) {
        if (!v) {
          return v1;
        }
        ;
        if (v) {
          return pure110(unit);
        }
        ;
        throw new Error("Failed pattern match at Control.Applicative (line 68, column 1 - line 68, column 65): " + [v.constructor.name, v1.constructor.name]);
      };
    };
  };
  var when = function(dictApplicative) {
    var pure110 = pure(dictApplicative);
    return function(v) {
      return function(v1) {
        if (v) {
          return v1;
        }
        ;
        if (!v) {
          return pure110(unit);
        }
        ;
        throw new Error("Failed pattern match at Control.Applicative (line 63, column 1 - line 63, column 63): " + [v.constructor.name, v1.constructor.name]);
      };
    };
  };
  var liftA1 = function(dictApplicative) {
    var apply2 = apply(dictApplicative.Apply0());
    var pure110 = pure(dictApplicative);
    return function(f) {
      return function(a2) {
        return apply2(pure110(f))(a2);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Bind/index.js
  var discard = function(dict) {
    return dict.discard;
  };
  var bindArray = {
    bind: arrayBind,
    Apply0: function() {
      return applyArray;
    }
  };
  var bind = function(dict) {
    return dict.bind;
  };
  var bindFlipped = function(dictBind) {
    return flip(bind(dictBind));
  };
  var composeKleisliFlipped = function(dictBind) {
    var bindFlipped12 = bindFlipped(dictBind);
    return function(f) {
      return function(g) {
        return function(a2) {
          return bindFlipped12(f)(g(a2));
        };
      };
    };
  };
  var discardUnit = {
    discard: function(dictBind) {
      return bind(dictBind);
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Array/foreign.js
  var replicateFill = function(count, value12) {
    if (count < 1) {
      return [];
    }
    var result = new Array(count);
    return result.fill(value12);
  };
  var replicatePolyfill = function(count, value12) {
    var result = [];
    var n = 0;
    for (var i2 = 0; i2 < count; i2++) {
      result[n++] = value12;
    }
    return result;
  };
  var replicateImpl = typeof Array.prototype.fill === "function" ? replicateFill : replicatePolyfill;
  var length = function(xs) {
    return xs.length;
  };
  var indexImpl = function(just, nothing, xs, i2) {
    return i2 < 0 || i2 >= xs.length ? nothing : just(xs[i2]);
  };
  var findIndexImpl = function(just, nothing, f, xs) {
    for (var i2 = 0, l = xs.length; i2 < l; i2++) {
      if (f(xs[i2])) return just(i2);
    }
    return nothing;
  };
  var _deleteAt = function(just, nothing, i2, l) {
    if (i2 < 0 || i2 >= l.length) return nothing;
    var l1 = l.slice();
    l1.splice(i2, 1);
    return just(l1);
  };
  var filterImpl = function(f, xs) {
    return xs.filter(f);
  };
  var unsafeIndexImpl = function(xs, n) {
    return xs[n];
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Semigroup/foreign.js
  var concatArray = function(xs) {
    return function(ys) {
      if (xs.length === 0) return ys;
      if (ys.length === 0) return xs;
      return xs.concat(ys);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Symbol/index.js
  var reflectSymbol = function(dict) {
    return dict.reflectSymbol;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Semigroup/index.js
  var semigroupArray = {
    append: concatArray
  };
  var append = function(dict) {
    return dict.append;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Monad/index.js
  var unlessM = function(dictMonad) {
    var bind25 = bind(dictMonad.Bind1());
    var unless2 = unless(dictMonad.Applicative0());
    return function(mb) {
      return function(m) {
        return bind25(mb)(function(b2) {
          return unless2(b2)(m);
        });
      };
    };
  };
  var ap = function(dictMonad) {
    var bind25 = bind(dictMonad.Bind1());
    var pure21 = pure(dictMonad.Applicative0());
    return function(f) {
      return function(a2) {
        return bind25(f)(function(f$prime) {
          return bind25(a2)(function(a$prime) {
            return pure21(f$prime(a$prime));
          });
        });
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Bounded/foreign.js
  var topChar = String.fromCharCode(65535);
  var bottomChar = String.fromCharCode(0);
  var topNumber = Number.POSITIVE_INFINITY;
  var bottomNumber = Number.NEGATIVE_INFINITY;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Ord/foreign.js
  var unsafeCompareImpl = function(lt) {
    return function(eq3) {
      return function(gt) {
        return function(x) {
          return function(y) {
            return x < y ? lt : x === y ? eq3 : gt;
          };
        };
      };
    };
  };
  var ordIntImpl = unsafeCompareImpl;
  var ordNumberImpl = unsafeCompareImpl;
  var ordStringImpl = unsafeCompareImpl;
  var ordCharImpl = unsafeCompareImpl;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Eq/foreign.js
  var refEq = function(r1) {
    return function(r2) {
      return r1 === r2;
    };
  };
  var eqBooleanImpl = refEq;
  var eqIntImpl = refEq;
  var eqNumberImpl = refEq;
  var eqCharImpl = refEq;
  var eqStringImpl = refEq;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Eq/index.js
  var eqUnit = {
    eq: function(v) {
      return function(v1) {
        return true;
      };
    }
  };
  var eqString = {
    eq: eqStringImpl
  };
  var eqNumber = {
    eq: eqNumberImpl
  };
  var eqInt = {
    eq: eqIntImpl
  };
  var eqChar = {
    eq: eqCharImpl
  };
  var eqBoolean = {
    eq: eqBooleanImpl
  };
  var eq = function(dict) {
    return dict.eq;
  };
  var eq2 = /* @__PURE__ */ eq(eqBoolean);
  var notEq = function(dictEq) {
    var eq3 = eq(dictEq);
    return function(x) {
      return function(y) {
        return eq2(eq3(x)(y))(false);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Ordering/index.js
  var LT = /* @__PURE__ */ function() {
    function LT2() {
    }
    ;
    LT2.value = new LT2();
    return LT2;
  }();
  var GT = /* @__PURE__ */ function() {
    function GT2() {
    }
    ;
    GT2.value = new GT2();
    return GT2;
  }();
  var EQ = /* @__PURE__ */ function() {
    function EQ2() {
    }
    ;
    EQ2.value = new EQ2();
    return EQ2;
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Ring/foreign.js
  var intSub = function(x) {
    return function(y) {
      return x - y | 0;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Semiring/foreign.js
  var intAdd = function(x) {
    return function(y) {
      return x + y | 0;
    };
  };
  var intMul = function(x) {
    return function(y) {
      return x * y | 0;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Semiring/index.js
  var semiringInt = {
    add: intAdd,
    zero: 0,
    mul: intMul,
    one: 1
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Ring/index.js
  var ringInt = {
    sub: intSub,
    Semiring0: function() {
      return semiringInt;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Ord/index.js
  var ordUnit = {
    compare: function(v) {
      return function(v1) {
        return EQ.value;
      };
    },
    Eq0: function() {
      return eqUnit;
    }
  };
  var ordString = /* @__PURE__ */ function() {
    return {
      compare: ordStringImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqString;
      }
    };
  }();
  var ordNumber = /* @__PURE__ */ function() {
    return {
      compare: ordNumberImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqNumber;
      }
    };
  }();
  var ordInt = /* @__PURE__ */ function() {
    return {
      compare: ordIntImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqInt;
      }
    };
  }();
  var ordChar = /* @__PURE__ */ function() {
    return {
      compare: ordCharImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqChar;
      }
    };
  }();
  var compare = function(dict) {
    return dict.compare;
  };
  var max = function(dictOrd) {
    var compare3 = compare(dictOrd);
    return function(x) {
      return function(y) {
        var v = compare3(x)(y);
        if (v instanceof LT) {
          return y;
        }
        ;
        if (v instanceof EQ) {
          return x;
        }
        ;
        if (v instanceof GT) {
          return x;
        }
        ;
        throw new Error("Failed pattern match at Data.Ord (line 181, column 3 - line 184, column 12): " + [v.constructor.name]);
      };
    };
  };
  var min = function(dictOrd) {
    var compare3 = compare(dictOrd);
    return function(x) {
      return function(y) {
        var v = compare3(x)(y);
        if (v instanceof LT) {
          return x;
        }
        ;
        if (v instanceof EQ) {
          return x;
        }
        ;
        if (v instanceof GT) {
          return y;
        }
        ;
        throw new Error("Failed pattern match at Data.Ord (line 172, column 3 - line 175, column 12): " + [v.constructor.name]);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Bounded/index.js
  var top = function(dict) {
    return dict.top;
  };
  var boundedChar = {
    top: topChar,
    bottom: bottomChar,
    Ord0: function() {
      return ordChar;
    }
  };
  var bottom = function(dict) {
    return dict.bottom;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Show/foreign.js
  var showIntImpl = function(n) {
    return n.toString();
  };
  var showNumberImpl = function(n) {
    var str = n.toString();
    return isNaN(str + ".0") ? str : str + ".0";
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Show/index.js
  var showNumber = {
    show: showNumberImpl
  };
  var showInt = {
    show: showIntImpl
  };
  var showBoolean = {
    show: function(v) {
      if (v) {
        return "true";
      }
      ;
      if (!v) {
        return "false";
      }
      ;
      throw new Error("Failed pattern match at Data.Show (line 29, column 1 - line 31, column 23): " + [v.constructor.name]);
    }
  };
  var show = function(dict) {
    return dict.show;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Maybe/index.js
  var identity3 = /* @__PURE__ */ identity(categoryFn);
  var Nothing = /* @__PURE__ */ function() {
    function Nothing2() {
    }
    ;
    Nothing2.value = new Nothing2();
    return Nothing2;
  }();
  var Just = /* @__PURE__ */ function() {
    function Just2(value0) {
      this.value0 = value0;
    }
    ;
    Just2.create = function(value0) {
      return new Just2(value0);
    };
    return Just2;
  }();
  var maybe = function(v) {
    return function(v1) {
      return function(v2) {
        if (v2 instanceof Nothing) {
          return v;
        }
        ;
        if (v2 instanceof Just) {
          return v1(v2.value0);
        }
        ;
        throw new Error("Failed pattern match at Data.Maybe (line 237, column 1 - line 237, column 51): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
      };
    };
  };
  var isNothing = /* @__PURE__ */ maybe(true)(/* @__PURE__ */ $$const(false));
  var isJust = /* @__PURE__ */ maybe(false)(/* @__PURE__ */ $$const(true));
  var functorMaybe = {
    map: function(v) {
      return function(v1) {
        if (v1 instanceof Just) {
          return new Just(v(v1.value0));
        }
        ;
        return Nothing.value;
      };
    }
  };
  var map2 = /* @__PURE__ */ map(functorMaybe);
  var fromMaybe = function(a2) {
    return maybe(a2)(identity3);
  };
  var fromJust = function() {
    return function(v) {
      if (v instanceof Just) {
        return v.value0;
      }
      ;
      throw new Error("Failed pattern match at Data.Maybe (line 288, column 1 - line 288, column 46): " + [v.constructor.name]);
    };
  };
  var applyMaybe = {
    apply: function(v) {
      return function(v1) {
        if (v instanceof Just) {
          return map2(v.value0)(v1);
        }
        ;
        if (v instanceof Nothing) {
          return Nothing.value;
        }
        ;
        throw new Error("Failed pattern match at Data.Maybe (line 67, column 1 - line 69, column 30): " + [v.constructor.name, v1.constructor.name]);
      };
    },
    Functor0: function() {
      return functorMaybe;
    }
  };
  var bindMaybe = {
    bind: function(v) {
      return function(v1) {
        if (v instanceof Just) {
          return v1(v.value0);
        }
        ;
        if (v instanceof Nothing) {
          return Nothing.value;
        }
        ;
        throw new Error("Failed pattern match at Data.Maybe (line 125, column 1 - line 127, column 28): " + [v.constructor.name, v1.constructor.name]);
      };
    },
    Apply0: function() {
      return applyMaybe;
    }
  };
  var applicativeMaybe = /* @__PURE__ */ function() {
    return {
      pure: Just.create,
      Apply0: function() {
        return applyMaybe;
      }
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Either/index.js
  var Left = /* @__PURE__ */ function() {
    function Left3(value0) {
      this.value0 = value0;
    }
    ;
    Left3.create = function(value0) {
      return new Left3(value0);
    };
    return Left3;
  }();
  var Right = /* @__PURE__ */ function() {
    function Right3(value0) {
      this.value0 = value0;
    }
    ;
    Right3.create = function(value0) {
      return new Right3(value0);
    };
    return Right3;
  }();
  var either = function(v) {
    return function(v1) {
      return function(v2) {
        if (v2 instanceof Left) {
          return v(v2.value0);
        }
        ;
        if (v2 instanceof Right) {
          return v1(v2.value0);
        }
        ;
        throw new Error("Failed pattern match at Data.Either (line 208, column 1 - line 208, column 64): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.EuclideanRing/foreign.js
  var intDegree = function(x) {
    return Math.min(Math.abs(x), 2147483647);
  };
  var intDiv = function(x) {
    return function(y) {
      if (y === 0) return 0;
      return y > 0 ? Math.floor(x / y) : -Math.floor(x / -y);
    };
  };
  var intMod = function(x) {
    return function(y) {
      if (y === 0) return 0;
      var yy = Math.abs(y);
      return (x % yy + yy) % yy;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.CommutativeRing/index.js
  var commutativeRingInt = {
    Ring0: function() {
      return ringInt;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.EuclideanRing/index.js
  var mod = function(dict) {
    return dict.mod;
  };
  var euclideanRingInt = {
    degree: intDegree,
    div: intDiv,
    mod: intMod,
    CommutativeRing0: function() {
      return commutativeRingInt;
    }
  };
  var div = function(dict) {
    return dict.div;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Monoid/index.js
  var mempty = function(dict) {
    return dict.mempty;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect/foreign.js
  var pureE = function(a2) {
    return function() {
      return a2;
    };
  };
  var bindE = function(a2) {
    return function(f) {
      return function() {
        return f(a2())();
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect/index.js
  var $runtime_lazy = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var monadEffect = {
    Applicative0: function() {
      return applicativeEffect;
    },
    Bind1: function() {
      return bindEffect;
    }
  };
  var bindEffect = {
    bind: bindE,
    Apply0: function() {
      return $lazy_applyEffect(0);
    }
  };
  var applicativeEffect = {
    pure: pureE,
    Apply0: function() {
      return $lazy_applyEffect(0);
    }
  };
  var $lazy_functorEffect = /* @__PURE__ */ $runtime_lazy("functorEffect", "Effect", function() {
    return {
      map: liftA1(applicativeEffect)
    };
  });
  var $lazy_applyEffect = /* @__PURE__ */ $runtime_lazy("applyEffect", "Effect", function() {
    return {
      apply: ap(monadEffect),
      Functor0: function() {
        return $lazy_functorEffect(0);
      }
    };
  });
  var functorEffect = /* @__PURE__ */ $lazy_functorEffect(20);
  var applyEffect = /* @__PURE__ */ $lazy_applyEffect(23);

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Ref/foreign.js
  var _new = function(val) {
    return function() {
      return { value: val };
    };
  };
  var read = function(ref3) {
    return function() {
      return ref3.value;
    };
  };
  var modifyImpl = function(f) {
    return function(ref3) {
      return function() {
        var t = f(ref3.value);
        ref3.value = t.state;
        return t.value;
      };
    };
  };
  var write = function(val) {
    return function(ref3) {
      return function() {
        ref3.value = val;
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Ref/index.js
  var $$void2 = /* @__PURE__ */ $$void(functorEffect);
  var $$new = _new;
  var modify$prime = modifyImpl;
  var modify = function(f) {
    return modify$prime(function(s) {
      var s$prime = f(s);
      return {
        state: s$prime,
        value: s$prime
      };
    });
  };
  var modify_ = function(f) {
    return function(s) {
      return $$void2(modify(f)(s));
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Monad.Rec.Class/index.js
  var bindFlipped2 = /* @__PURE__ */ bindFlipped(bindEffect);
  var map3 = /* @__PURE__ */ map(functorEffect);
  var Loop = /* @__PURE__ */ function() {
    function Loop2(value0) {
      this.value0 = value0;
    }
    ;
    Loop2.create = function(value0) {
      return new Loop2(value0);
    };
    return Loop2;
  }();
  var Done = /* @__PURE__ */ function() {
    function Done2(value0) {
      this.value0 = value0;
    }
    ;
    Done2.create = function(value0) {
      return new Done2(value0);
    };
    return Done2;
  }();
  var tailRecM = function(dict) {
    return dict.tailRecM;
  };
  var monadRecEffect = {
    tailRecM: function(f) {
      return function(a2) {
        var fromDone = function(v) {
          if (v instanceof Done) {
            return v.value0;
          }
          ;
          throw new Error("Failed pattern match at Control.Monad.Rec.Class (line 137, column 30 - line 137, column 44): " + [v.constructor.name]);
        };
        return function __do12() {
          var r = bindFlipped2($$new)(f(a2))();
          (function() {
            while (!function __do13() {
              var v = read(r)();
              if (v instanceof Loop) {
                var e = f(v.value0)();
                write(e)(r)();
                return false;
              }
              ;
              if (v instanceof Done) {
                return true;
              }
              ;
              throw new Error("Failed pattern match at Control.Monad.Rec.Class (line 128, column 22 - line 133, column 28): " + [v.constructor.name]);
            }()) {
            }
            ;
            return {};
          })();
          return map3(fromDone)(read(r))();
        };
      };
    },
    Monad0: function() {
      return monadEffect;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.HeytingAlgebra/foreign.js
  var boolConj = function(b1) {
    return function(b2) {
      return b1 && b2;
    };
  };
  var boolDisj = function(b1) {
    return function(b2) {
      return b1 || b2;
    };
  };
  var boolNot = function(b2) {
    return !b2;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.HeytingAlgebra/index.js
  var tt = function(dict) {
    return dict.tt;
  };
  var not = function(dict) {
    return dict.not;
  };
  var implies = function(dict) {
    return dict.implies;
  };
  var ff = function(dict) {
    return dict.ff;
  };
  var disj = function(dict) {
    return dict.disj;
  };
  var heytingAlgebraBoolean = {
    ff: false,
    tt: true,
    implies: function(a2) {
      return function(b2) {
        return disj(heytingAlgebraBoolean)(not(heytingAlgebraBoolean)(a2))(b2);
      };
    },
    conj: boolConj,
    disj: boolDisj,
    not: boolNot
  };
  var conj = function(dict) {
    return dict.conj;
  };
  var heytingAlgebraFunction = function(dictHeytingAlgebra) {
    var ff1 = ff(dictHeytingAlgebra);
    var tt1 = tt(dictHeytingAlgebra);
    var implies1 = implies(dictHeytingAlgebra);
    var conj1 = conj(dictHeytingAlgebra);
    var disj1 = disj(dictHeytingAlgebra);
    var not1 = not(dictHeytingAlgebra);
    return {
      ff: function(v) {
        return ff1;
      },
      tt: function(v) {
        return tt1;
      },
      implies: function(f) {
        return function(g) {
          return function(a2) {
            return implies1(f(a2))(g(a2));
          };
        };
      },
      conj: function(f) {
        return function(g) {
          return function(a2) {
            return conj1(f(a2))(g(a2));
          };
        };
      },
      disj: function(f) {
        return function(g) {
          return function(a2) {
            return disj1(f(a2))(g(a2));
          };
        };
      },
      not: function(f) {
        return function(a2) {
          return not1(f(a2));
        };
      }
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Foldable/foreign.js
  var foldrArray = function(f) {
    return function(init2) {
      return function(xs) {
        var acc = init2;
        var len = xs.length;
        for (var i2 = len - 1; i2 >= 0; i2--) {
          acc = f(xs[i2])(acc);
        }
        return acc;
      };
    };
  };
  var foldlArray = function(f) {
    return function(init2) {
      return function(xs) {
        var acc = init2;
        var len = xs.length;
        for (var i2 = 0; i2 < len; i2++) {
          acc = f(acc)(xs[i2]);
        }
        return acc;
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Plus/index.js
  var empty = function(dict) {
    return dict.empty;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Tuple/index.js
  var Tuple = /* @__PURE__ */ function() {
    function Tuple2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Tuple2.create = function(value0) {
      return function(value1) {
        return new Tuple2(value0, value1);
      };
    };
    return Tuple2;
  }();
  var snd = function(v) {
    return v.value1;
  };
  var functorTuple = {
    map: function(f) {
      return function(m) {
        return new Tuple(m.value0, f(m.value1));
      };
    }
  };
  var fst = function(v) {
    return v.value0;
  };
  var eqTuple = function(dictEq) {
    var eq3 = eq(dictEq);
    return function(dictEq1) {
      var eq13 = eq(dictEq1);
      return {
        eq: function(x) {
          return function(y) {
            return eq3(x.value0)(y.value0) && eq13(x.value1)(y.value1);
          };
        }
      };
    };
  };
  var ordTuple = function(dictOrd) {
    var compare2 = compare(dictOrd);
    var eqTuple1 = eqTuple(dictOrd.Eq0());
    return function(dictOrd1) {
      var compare12 = compare(dictOrd1);
      var eqTuple2 = eqTuple1(dictOrd1.Eq0());
      return {
        compare: function(x) {
          return function(y) {
            var v = compare2(x.value0)(y.value0);
            if (v instanceof LT) {
              return LT.value;
            }
            ;
            if (v instanceof GT) {
              return GT.value;
            }
            ;
            return compare12(x.value1)(y.value1);
          };
        },
        Eq0: function() {
          return eqTuple2;
        }
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Bifunctor/index.js
  var bimap = function(dict) {
    return dict.bimap;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Unsafe.Coerce/foreign.js
  var unsafeCoerce2 = function(x) {
    return x;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Safe.Coerce/index.js
  var coerce = function() {
    return unsafeCoerce2;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Newtype/index.js
  var coerce2 = /* @__PURE__ */ coerce();
  var unwrap = function() {
    return coerce2;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Foldable/index.js
  var foldr = function(dict) {
    return dict.foldr;
  };
  var traverse_ = function(dictApplicative) {
    var applySecond9 = applySecond(dictApplicative.Apply0());
    var pure21 = pure(dictApplicative);
    return function(dictFoldable) {
      var foldr22 = foldr(dictFoldable);
      return function(f) {
        return foldr22(function($454) {
          return applySecond9(f($454));
        })(pure21(unit));
      };
    };
  };
  var for_ = function(dictApplicative) {
    var traverse_17 = traverse_(dictApplicative);
    return function(dictFoldable) {
      return flip(traverse_17(dictFoldable));
    };
  };
  var foldl = function(dict) {
    return dict.foldl;
  };
  var foldableMaybe = {
    foldr: function(v) {
      return function(v1) {
        return function(v2) {
          if (v2 instanceof Nothing) {
            return v1;
          }
          ;
          if (v2 instanceof Just) {
            return v(v2.value0)(v1);
          }
          ;
          throw new Error("Failed pattern match at Data.Foldable (line 138, column 1 - line 144, column 27): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
        };
      };
    },
    foldl: function(v) {
      return function(v1) {
        return function(v2) {
          if (v2 instanceof Nothing) {
            return v1;
          }
          ;
          if (v2 instanceof Just) {
            return v(v1)(v2.value0);
          }
          ;
          throw new Error("Failed pattern match at Data.Foldable (line 138, column 1 - line 144, column 27): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
        };
      };
    },
    foldMap: function(dictMonoid) {
      var mempty2 = mempty(dictMonoid);
      return function(v) {
        return function(v1) {
          if (v1 instanceof Nothing) {
            return mempty2;
          }
          ;
          if (v1 instanceof Just) {
            return v(v1.value0);
          }
          ;
          throw new Error("Failed pattern match at Data.Foldable (line 138, column 1 - line 144, column 27): " + [v.constructor.name, v1.constructor.name]);
        };
      };
    }
  };
  var foldMapDefaultR = function(dictFoldable) {
    var foldr22 = foldr(dictFoldable);
    return function(dictMonoid) {
      var append10 = append(dictMonoid.Semigroup0());
      var mempty2 = mempty(dictMonoid);
      return function(f) {
        return foldr22(function(x) {
          return function(acc) {
            return append10(f(x))(acc);
          };
        })(mempty2);
      };
    };
  };
  var foldableArray = {
    foldr: foldrArray,
    foldl: foldlArray,
    foldMap: function(dictMonoid) {
      return foldMapDefaultR(foldableArray)(dictMonoid);
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Function.Uncurried/foreign.js
  var runFn2 = function(fn) {
    return function(a2) {
      return function(b2) {
        return fn(a2, b2);
      };
    };
  };
  var runFn4 = function(fn) {
    return function(a2) {
      return function(b2) {
        return function(c) {
          return function(d) {
            return fn(a2, b2, c, d);
          };
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.FunctorWithIndex/foreign.js
  var mapWithIndexArray = function(f) {
    return function(xs) {
      var l = xs.length;
      var result = Array(l);
      for (var i2 = 0; i2 < l; i2++) {
        result[i2] = f(i2)(xs[i2]);
      }
      return result;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.FunctorWithIndex/index.js
  var mapWithIndex = function(dict) {
    return dict.mapWithIndex;
  };
  var functorWithIndexArray = {
    mapWithIndex: mapWithIndexArray,
    Functor0: function() {
      return functorArray;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Traversable/foreign.js
  var traverseArrayImpl = /* @__PURE__ */ function() {
    function array1(a2) {
      return [a2];
    }
    function array2(a2) {
      return function(b2) {
        return [a2, b2];
      };
    }
    function array3(a2) {
      return function(b2) {
        return function(c) {
          return [a2, b2, c];
        };
      };
    }
    function concat2(xs) {
      return function(ys) {
        return xs.concat(ys);
      };
    }
    return function(apply2) {
      return function(map36) {
        return function(pure21) {
          return function(f) {
            return function(array) {
              function go2(bot, top2) {
                switch (top2 - bot) {
                  case 0:
                    return pure21([]);
                  case 1:
                    return map36(array1)(f(array[bot]));
                  case 2:
                    return apply2(map36(array2)(f(array[bot])))(f(array[bot + 1]));
                  case 3:
                    return apply2(apply2(map36(array3)(f(array[bot])))(f(array[bot + 1])))(f(array[bot + 2]));
                  default:
                    var pivot = bot + Math.floor((top2 - bot) / 4) * 2;
                    return apply2(map36(concat2)(go2(bot, pivot)))(go2(pivot, top2));
                }
              }
              return go2(0, array.length);
            };
          };
        };
      };
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Traversable/index.js
  var identity4 = /* @__PURE__ */ identity(categoryFn);
  var traverse = function(dict) {
    return dict.traverse;
  };
  var sequenceDefault = function(dictTraversable) {
    var traverse22 = traverse(dictTraversable);
    return function(dictApplicative) {
      return traverse22(dictApplicative)(identity4);
    };
  };
  var traversableArray = {
    traverse: function(dictApplicative) {
      var Apply0 = dictApplicative.Apply0();
      return traverseArrayImpl(apply(Apply0))(map(Apply0.Functor0()))(pure(dictApplicative));
    },
    sequence: function(dictApplicative) {
      return sequenceDefault(traversableArray)(dictApplicative);
    },
    Functor0: function() {
      return functorArray;
    },
    Foldable1: function() {
      return foldableArray;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Unfoldable/foreign.js
  var unfoldrArrayImpl = function(isNothing2) {
    return function(fromJust5) {
      return function(fst2) {
        return function(snd2) {
          return function(f) {
            return function(b2) {
              var result = [];
              var value12 = b2;
              while (true) {
                var maybe2 = f(value12);
                if (isNothing2(maybe2)) return result;
                var tuple = fromJust5(maybe2);
                result.push(fst2(tuple));
                value12 = snd2(tuple);
              }
            };
          };
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Unfoldable1/foreign.js
  var unfoldr1ArrayImpl = function(isNothing2) {
    return function(fromJust5) {
      return function(fst2) {
        return function(snd2) {
          return function(f) {
            return function(b2) {
              var result = [];
              var value12 = b2;
              while (true) {
                var tuple = f(value12);
                result.push(fst2(tuple));
                var maybe2 = snd2(tuple);
                if (isNothing2(maybe2)) return result;
                value12 = fromJust5(maybe2);
              }
            };
          };
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Unfoldable1/index.js
  var fromJust2 = /* @__PURE__ */ fromJust();
  var unfoldable1Array = {
    unfoldr1: /* @__PURE__ */ unfoldr1ArrayImpl(isNothing)(fromJust2)(fst)(snd)
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Unfoldable/index.js
  var fromJust3 = /* @__PURE__ */ fromJust();
  var unfoldr = function(dict) {
    return dict.unfoldr;
  };
  var unfoldableArray = {
    unfoldr: /* @__PURE__ */ unfoldrArrayImpl(isNothing)(fromJust3)(fst)(snd),
    Unfoldable10: function() {
      return unfoldable1Array;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Array/index.js
  var map4 = /* @__PURE__ */ map(functorMaybe);
  var fromJust4 = /* @__PURE__ */ fromJust();
  var traverse2 = /* @__PURE__ */ traverse(traversableArray);
  var unsafeIndex = function() {
    return runFn2(unsafeIndexImpl);
  };
  var unsafeIndex1 = /* @__PURE__ */ unsafeIndex();
  var singleton2 = function(a2) {
    return [a2];
  };
  var $$null = function(xs) {
    return length(xs) === 0;
  };
  var mapWithIndex2 = /* @__PURE__ */ mapWithIndex(functorWithIndexArray);
  var index = /* @__PURE__ */ function() {
    return runFn4(indexImpl)(Just.create)(Nothing.value);
  }();
  var last = function(xs) {
    return index(xs)(length(xs) - 1 | 0);
  };
  var head = function(xs) {
    return index(xs)(0);
  };
  var findIndex = /* @__PURE__ */ function() {
    return runFn4(findIndexImpl)(Just.create)(Nothing.value);
  }();
  var find2 = function(f) {
    return function(xs) {
      return map4(unsafeIndex1(xs))(findIndex(f)(xs));
    };
  };
  var filter = /* @__PURE__ */ runFn2(filterImpl);
  var deleteAt = /* @__PURE__ */ function() {
    return runFn4(_deleteAt)(Just.create)(Nothing.value);
  }();
  var deleteBy = function(v) {
    return function(v1) {
      return function(v2) {
        if (v2.length === 0) {
          return [];
        }
        ;
        return maybe(v2)(function(i2) {
          return fromJust4(deleteAt(i2)(v2));
        })(findIndex(v(v1))(v2));
      };
    };
  };
  var concatMap = /* @__PURE__ */ flip(/* @__PURE__ */ bind(bindArray));
  var mapMaybe = function(f) {
    return concatMap(function() {
      var $189 = maybe([])(singleton2);
      return function($190) {
        return $189(f($190));
      };
    }());
  };
  var filterA = function(dictApplicative) {
    var traverse12 = traverse2(dictApplicative);
    var map36 = map(dictApplicative.Apply0().Functor0());
    return function(p2) {
      var $191 = map36(mapMaybe(function(v) {
        if (v.value1) {
          return new Just(v.value0);
        }
        ;
        return Nothing.value;
      }));
      var $192 = traverse12(function(x) {
        return map36(Tuple.create(x))(p2(x));
      });
      return function($193) {
        return $191($192($193));
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.String.CodePoints/foreign.js
  var hasArrayFrom = typeof Array.from === "function";
  var hasStringIterator = typeof Symbol !== "undefined" && Symbol != null && typeof Symbol.iterator !== "undefined" && typeof String.prototype[Symbol.iterator] === "function";
  var hasFromCodePoint = typeof String.prototype.fromCodePoint === "function";
  var hasCodePointAt = typeof String.prototype.codePointAt === "function";
  var _unsafeCodePointAt0 = function(fallback) {
    return hasCodePointAt ? function(str) {
      return str.codePointAt(0);
    } : fallback;
  };
  var _singleton = function(fallback) {
    return hasFromCodePoint ? String.fromCodePoint : fallback;
  };
  var _take = function(fallback) {
    return function(n) {
      if (hasStringIterator) {
        return function(str) {
          var accum = "";
          var iter = str[Symbol.iterator]();
          for (var i2 = 0; i2 < n; ++i2) {
            var o = iter.next();
            if (o.done) return accum;
            accum += o.value;
          }
          return accum;
        };
      }
      return fallback(n);
    };
  };
  var _toCodePointArray = function(fallback) {
    return function(unsafeCodePointAt02) {
      if (hasArrayFrom) {
        return function(str) {
          return Array.from(str, unsafeCodePointAt02);
        };
      }
      return fallback;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Enum/foreign.js
  function toCharCode(c) {
    return c.charCodeAt(0);
  }
  function fromCharCode(c) {
    return String.fromCharCode(c);
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Enum/index.js
  var bottom1 = /* @__PURE__ */ bottom(boundedChar);
  var top1 = /* @__PURE__ */ top(boundedChar);
  var toEnum = function(dict) {
    return dict.toEnum;
  };
  var fromEnum = function(dict) {
    return dict.fromEnum;
  };
  var toEnumWithDefaults = function(dictBoundedEnum) {
    var toEnum1 = toEnum(dictBoundedEnum);
    var fromEnum1 = fromEnum(dictBoundedEnum);
    var bottom2 = bottom(dictBoundedEnum.Bounded0());
    return function(low2) {
      return function(high2) {
        return function(x) {
          var v = toEnum1(x);
          if (v instanceof Just) {
            return v.value0;
          }
          ;
          if (v instanceof Nothing) {
            var $140 = x < fromEnum1(bottom2);
            if ($140) {
              return low2;
            }
            ;
            return high2;
          }
          ;
          throw new Error("Failed pattern match at Data.Enum (line 158, column 33 - line 160, column 62): " + [v.constructor.name]);
        };
      };
    };
  };
  var defaultSucc = function(toEnum$prime) {
    return function(fromEnum$prime) {
      return function(a2) {
        return toEnum$prime(fromEnum$prime(a2) + 1 | 0);
      };
    };
  };
  var defaultPred = function(toEnum$prime) {
    return function(fromEnum$prime) {
      return function(a2) {
        return toEnum$prime(fromEnum$prime(a2) - 1 | 0);
      };
    };
  };
  var charToEnum = function(v) {
    if (v >= toCharCode(bottom1) && v <= toCharCode(top1)) {
      return new Just(fromCharCode(v));
    }
    ;
    return Nothing.value;
  };
  var enumChar = {
    succ: /* @__PURE__ */ defaultSucc(charToEnum)(toCharCode),
    pred: /* @__PURE__ */ defaultPred(charToEnum)(toCharCode),
    Ord0: function() {
      return ordChar;
    }
  };
  var boundedEnumChar = /* @__PURE__ */ function() {
    return {
      cardinality: toCharCode(top1) - toCharCode(bottom1) | 0,
      toEnum: charToEnum,
      fromEnum: toCharCode,
      Bounded0: function() {
        return boundedChar;
      },
      Enum1: function() {
        return enumChar;
      }
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Int/foreign.js
  var toNumber = function(n) {
    return n;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.String.CodeUnits/foreign.js
  var singleton3 = function(c) {
    return c;
  };
  var length2 = function(s) {
    return s.length;
  };
  var _indexOf = function(just) {
    return function(nothing) {
      return function(x) {
        return function(s) {
          var i2 = s.indexOf(x);
          return i2 === -1 ? nothing : just(i2);
        };
      };
    };
  };
  var take = function(n) {
    return function(s) {
      return s.substr(0, n);
    };
  };
  var drop = function(n) {
    return function(s) {
      return s.substring(n);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.String.Unsafe/foreign.js
  var charAt = function(i2) {
    return function(s) {
      if (i2 >= 0 && i2 < s.length) return s.charAt(i2);
      throw new Error("Data.String.Unsafe.charAt: Invalid index.");
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.String.CodeUnits/index.js
  var indexOf = /* @__PURE__ */ function() {
    return _indexOf(Just.create)(Nothing.value);
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.String.Common/foreign.js
  var split = function(sep) {
    return function(s) {
      return s.split(sep);
    };
  };
  var trim = function(s) {
    return s.trim();
  };
  var joinWith = function(s) {
    return function(xs) {
      return xs.join(s);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.String.CodePoints/index.js
  var fromEnum2 = /* @__PURE__ */ fromEnum(boundedEnumChar);
  var map5 = /* @__PURE__ */ map(functorMaybe);
  var unfoldr2 = /* @__PURE__ */ unfoldr(unfoldableArray);
  var div2 = /* @__PURE__ */ div(euclideanRingInt);
  var mod2 = /* @__PURE__ */ mod(euclideanRingInt);
  var unsurrogate = function(lead) {
    return function(trail) {
      return (((lead - 55296 | 0) * 1024 | 0) + (trail - 56320 | 0) | 0) + 65536 | 0;
    };
  };
  var isTrail = function(cu) {
    return 56320 <= cu && cu <= 57343;
  };
  var isLead = function(cu) {
    return 55296 <= cu && cu <= 56319;
  };
  var uncons = function(s) {
    var v = length2(s);
    if (v === 0) {
      return Nothing.value;
    }
    ;
    if (v === 1) {
      return new Just({
        head: fromEnum2(charAt(0)(s)),
        tail: ""
      });
    }
    ;
    var cu1 = fromEnum2(charAt(1)(s));
    var cu0 = fromEnum2(charAt(0)(s));
    var $43 = isLead(cu0) && isTrail(cu1);
    if ($43) {
      return new Just({
        head: unsurrogate(cu0)(cu1),
        tail: drop(2)(s)
      });
    }
    ;
    return new Just({
      head: cu0,
      tail: drop(1)(s)
    });
  };
  var unconsButWithTuple = function(s) {
    return map5(function(v) {
      return new Tuple(v.head, v.tail);
    })(uncons(s));
  };
  var toCodePointArrayFallback = function(s) {
    return unfoldr2(unconsButWithTuple)(s);
  };
  var unsafeCodePointAt0Fallback = function(s) {
    var cu0 = fromEnum2(charAt(0)(s));
    var $47 = isLead(cu0) && length2(s) > 1;
    if ($47) {
      var cu1 = fromEnum2(charAt(1)(s));
      var $48 = isTrail(cu1);
      if ($48) {
        return unsurrogate(cu0)(cu1);
      }
      ;
      return cu0;
    }
    ;
    return cu0;
  };
  var unsafeCodePointAt0 = /* @__PURE__ */ _unsafeCodePointAt0(unsafeCodePointAt0Fallback);
  var toCodePointArray = /* @__PURE__ */ _toCodePointArray(toCodePointArrayFallback)(unsafeCodePointAt0);
  var length3 = function($74) {
    return length(toCodePointArray($74));
  };
  var indexOf2 = function(p2) {
    return function(s) {
      return map5(function(i2) {
        return length3(take(i2)(s));
      })(indexOf(p2)(s));
    };
  };
  var fromCharCode2 = /* @__PURE__ */ function() {
    var $75 = toEnumWithDefaults(boundedEnumChar)(bottom(boundedChar))(top(boundedChar));
    return function($76) {
      return singleton3($75($76));
    };
  }();
  var singletonFallback = function(v) {
    if (v <= 65535) {
      return fromCharCode2(v);
    }
    ;
    var lead = div2(v - 65536 | 0)(1024) + 55296 | 0;
    var trail = mod2(v - 65536 | 0)(1024) + 56320 | 0;
    return fromCharCode2(lead) + fromCharCode2(trail);
  };
  var singleton4 = /* @__PURE__ */ _singleton(singletonFallback);
  var takeFallback = function(v) {
    return function(v1) {
      if (v < 1) {
        return "";
      }
      ;
      var v2 = uncons(v1);
      if (v2 instanceof Just) {
        return singleton4(v2.value0.head) + takeFallback(v - 1 | 0)(v2.value0.tail);
      }
      ;
      return v1;
    };
  };
  var take2 = /* @__PURE__ */ _take(takeFallback);
  var splitAt2 = function(i2) {
    return function(s) {
      var before = take2(i2)(s);
      return {
        before,
        after: drop(length2(before))(s)
      };
    };
  };
  var drop2 = function(n) {
    return function(s) {
      return drop(length2(take2(n)(s)))(s);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Aff/foreign.js
  var Aff = function() {
    var EMPTY = {};
    var PURE = "Pure";
    var THROW = "Throw";
    var CATCH = "Catch";
    var SYNC = "Sync";
    var ASYNC = "Async";
    var BIND = "Bind";
    var BRACKET = "Bracket";
    var FORK = "Fork";
    var SEQ = "Sequential";
    var MAP = "Map";
    var APPLY = "Apply";
    var ALT = "Alt";
    var CONS = "Cons";
    var RESUME = "Resume";
    var RELEASE = "Release";
    var FINALIZER = "Finalizer";
    var FINALIZED = "Finalized";
    var FORKED = "Forked";
    var FIBER = "Fiber";
    var THUNK = "Thunk";
    function Aff2(tag, _1, _2, _3) {
      this.tag = tag;
      this._1 = _1;
      this._2 = _2;
      this._3 = _3;
    }
    function AffCtr(tag) {
      var fn = function(_1, _2, _3) {
        return new Aff2(tag, _1, _2, _3);
      };
      fn.tag = tag;
      return fn;
    }
    function nonCanceler2(error4) {
      return new Aff2(PURE, void 0);
    }
    function runEff(eff) {
      try {
        eff();
      } catch (error4) {
        setTimeout(function() {
          throw error4;
        }, 0);
      }
    }
    function runSync(left, right, eff) {
      try {
        return right(eff());
      } catch (error4) {
        return left(error4);
      }
    }
    function runAsync(left, eff, k) {
      try {
        return eff(k)();
      } catch (error4) {
        k(left(error4))();
        return nonCanceler2;
      }
    }
    var Scheduler = function() {
      var limit = 1024;
      var size4 = 0;
      var ix = 0;
      var queue = new Array(limit);
      var draining = false;
      function drain() {
        var thunk;
        draining = true;
        while (size4 !== 0) {
          size4--;
          thunk = queue[ix];
          queue[ix] = void 0;
          ix = (ix + 1) % limit;
          thunk();
        }
        draining = false;
      }
      return {
        isDraining: function() {
          return draining;
        },
        enqueue: function(cb) {
          var i2, tmp;
          if (size4 === limit) {
            tmp = draining;
            drain();
            draining = tmp;
          }
          queue[(ix + size4) % limit] = cb;
          size4++;
          if (!draining) {
            drain();
          }
        }
      };
    }();
    function Supervisor(util) {
      var fibers = {};
      var fiberId = 0;
      var count = 0;
      return {
        register: function(fiber) {
          var fid = fiberId++;
          fiber.onComplete({
            rethrow: true,
            handler: function(result) {
              return function() {
                count--;
                delete fibers[fid];
              };
            }
          })();
          fibers[fid] = fiber;
          count++;
        },
        isEmpty: function() {
          return count === 0;
        },
        killAll: function(killError, cb) {
          return function() {
            if (count === 0) {
              return cb();
            }
            var killCount = 0;
            var kills = {};
            function kill2(fid) {
              kills[fid] = fibers[fid].kill(killError, function(result) {
                return function() {
                  delete kills[fid];
                  killCount--;
                  if (util.isLeft(result) && util.fromLeft(result)) {
                    setTimeout(function() {
                      throw util.fromLeft(result);
                    }, 0);
                  }
                  if (killCount === 0) {
                    cb();
                  }
                };
              })();
            }
            for (var k in fibers) {
              if (fibers.hasOwnProperty(k)) {
                killCount++;
                kill2(k);
              }
            }
            fibers = {};
            fiberId = 0;
            count = 0;
            return function(error4) {
              return new Aff2(SYNC, function() {
                for (var k2 in kills) {
                  if (kills.hasOwnProperty(k2)) {
                    kills[k2]();
                  }
                }
              });
            };
          };
        }
      };
    }
    var SUSPENDED = 0;
    var CONTINUE = 1;
    var STEP_BIND = 2;
    var STEP_RESULT = 3;
    var PENDING = 4;
    var RETURN = 5;
    var COMPLETED = 6;
    function Fiber(util, supervisor, aff) {
      var runTick = 0;
      var status = SUSPENDED;
      var step4 = aff;
      var fail2 = null;
      var interrupt = null;
      var bhead = null;
      var btail = null;
      var attempts = null;
      var bracketCount = 0;
      var joinId = 0;
      var joins = null;
      var rethrow = true;
      function run3(localRunTick) {
        var tmp, result, attempt;
        while (true) {
          tmp = null;
          result = null;
          attempt = null;
          switch (status) {
            case STEP_BIND:
              status = CONTINUE;
              try {
                step4 = bhead(step4);
                if (btail === null) {
                  bhead = null;
                } else {
                  bhead = btail._1;
                  btail = btail._2;
                }
              } catch (e) {
                status = RETURN;
                fail2 = util.left(e);
                step4 = null;
              }
              break;
            case STEP_RESULT:
              if (util.isLeft(step4)) {
                status = RETURN;
                fail2 = step4;
                step4 = null;
              } else if (bhead === null) {
                status = RETURN;
              } else {
                status = STEP_BIND;
                step4 = util.fromRight(step4);
              }
              break;
            case CONTINUE:
              switch (step4.tag) {
                case BIND:
                  if (bhead) {
                    btail = new Aff2(CONS, bhead, btail);
                  }
                  bhead = step4._2;
                  status = CONTINUE;
                  step4 = step4._1;
                  break;
                case PURE:
                  if (bhead === null) {
                    status = RETURN;
                    step4 = util.right(step4._1);
                  } else {
                    status = STEP_BIND;
                    step4 = step4._1;
                  }
                  break;
                case SYNC:
                  status = STEP_RESULT;
                  step4 = runSync(util.left, util.right, step4._1);
                  break;
                case ASYNC:
                  status = PENDING;
                  step4 = runAsync(util.left, step4._1, function(result2) {
                    return function() {
                      if (runTick !== localRunTick) {
                        return;
                      }
                      runTick++;
                      Scheduler.enqueue(function() {
                        if (runTick !== localRunTick + 1) {
                          return;
                        }
                        status = STEP_RESULT;
                        step4 = result2;
                        run3(runTick);
                      });
                    };
                  });
                  return;
                case THROW:
                  status = RETURN;
                  fail2 = util.left(step4._1);
                  step4 = null;
                  break;
                // Enqueue the Catch so that we can call the error handler later on
                // in case of an exception.
                case CATCH:
                  if (bhead === null) {
                    attempts = new Aff2(CONS, step4, attempts, interrupt);
                  } else {
                    attempts = new Aff2(CONS, step4, new Aff2(CONS, new Aff2(RESUME, bhead, btail), attempts, interrupt), interrupt);
                  }
                  bhead = null;
                  btail = null;
                  status = CONTINUE;
                  step4 = step4._1;
                  break;
                // Enqueue the Bracket so that we can call the appropriate handlers
                // after resource acquisition.
                case BRACKET:
                  bracketCount++;
                  if (bhead === null) {
                    attempts = new Aff2(CONS, step4, attempts, interrupt);
                  } else {
                    attempts = new Aff2(CONS, step4, new Aff2(CONS, new Aff2(RESUME, bhead, btail), attempts, interrupt), interrupt);
                  }
                  bhead = null;
                  btail = null;
                  status = CONTINUE;
                  step4 = step4._1;
                  break;
                case FORK:
                  status = STEP_RESULT;
                  tmp = Fiber(util, supervisor, step4._2);
                  if (supervisor) {
                    supervisor.register(tmp);
                  }
                  if (step4._1) {
                    tmp.run();
                  }
                  step4 = util.right(tmp);
                  break;
                case SEQ:
                  status = CONTINUE;
                  step4 = sequential3(util, supervisor, step4._1);
                  break;
              }
              break;
            case RETURN:
              bhead = null;
              btail = null;
              if (attempts === null) {
                status = COMPLETED;
                step4 = interrupt || fail2 || step4;
              } else {
                tmp = attempts._3;
                attempt = attempts._1;
                attempts = attempts._2;
                switch (attempt.tag) {
                  // We cannot recover from an unmasked interrupt. Otherwise we should
                  // continue stepping, or run the exception handler if an exception
                  // was raised.
                  case CATCH:
                    if (interrupt && interrupt !== tmp && bracketCount === 0) {
                      status = RETURN;
                    } else if (fail2) {
                      status = CONTINUE;
                      step4 = attempt._2(util.fromLeft(fail2));
                      fail2 = null;
                    }
                    break;
                  // We cannot resume from an unmasked interrupt or exception.
                  case RESUME:
                    if (interrupt && interrupt !== tmp && bracketCount === 0 || fail2) {
                      status = RETURN;
                    } else {
                      bhead = attempt._1;
                      btail = attempt._2;
                      status = STEP_BIND;
                      step4 = util.fromRight(step4);
                    }
                    break;
                  // If we have a bracket, we should enqueue the handlers,
                  // and continue with the success branch only if the fiber has
                  // not been interrupted. If the bracket acquisition failed, we
                  // should not run either.
                  case BRACKET:
                    bracketCount--;
                    if (fail2 === null) {
                      result = util.fromRight(step4);
                      attempts = new Aff2(CONS, new Aff2(RELEASE, attempt._2, result), attempts, tmp);
                      if (interrupt === tmp || bracketCount > 0) {
                        status = CONTINUE;
                        step4 = attempt._3(result);
                      }
                    }
                    break;
                  // Enqueue the appropriate handler. We increase the bracket count
                  // because it should not be cancelled.
                  case RELEASE:
                    attempts = new Aff2(CONS, new Aff2(FINALIZED, step4, fail2), attempts, interrupt);
                    status = CONTINUE;
                    if (interrupt && interrupt !== tmp && bracketCount === 0) {
                      step4 = attempt._1.killed(util.fromLeft(interrupt))(attempt._2);
                    } else if (fail2) {
                      step4 = attempt._1.failed(util.fromLeft(fail2))(attempt._2);
                    } else {
                      step4 = attempt._1.completed(util.fromRight(step4))(attempt._2);
                    }
                    fail2 = null;
                    bracketCount++;
                    break;
                  case FINALIZER:
                    bracketCount++;
                    attempts = new Aff2(CONS, new Aff2(FINALIZED, step4, fail2), attempts, interrupt);
                    status = CONTINUE;
                    step4 = attempt._1;
                    break;
                  case FINALIZED:
                    bracketCount--;
                    status = RETURN;
                    step4 = attempt._1;
                    fail2 = attempt._2;
                    break;
                }
              }
              break;
            case COMPLETED:
              for (var k in joins) {
                if (joins.hasOwnProperty(k)) {
                  rethrow = rethrow && joins[k].rethrow;
                  runEff(joins[k].handler(step4));
                }
              }
              joins = null;
              if (interrupt && fail2) {
                setTimeout(function() {
                  throw util.fromLeft(fail2);
                }, 0);
              } else if (util.isLeft(step4) && rethrow) {
                setTimeout(function() {
                  if (rethrow) {
                    throw util.fromLeft(step4);
                  }
                }, 0);
              }
              return;
            case SUSPENDED:
              status = CONTINUE;
              break;
            case PENDING:
              return;
          }
        }
      }
      function onComplete(join4) {
        return function() {
          if (status === COMPLETED) {
            rethrow = rethrow && join4.rethrow;
            join4.handler(step4)();
            return function() {
            };
          }
          var jid = joinId++;
          joins = joins || {};
          joins[jid] = join4;
          return function() {
            if (joins !== null) {
              delete joins[jid];
            }
          };
        };
      }
      function kill2(error4, cb) {
        return function() {
          if (status === COMPLETED) {
            cb(util.right(void 0))();
            return function() {
            };
          }
          var canceler = onComplete({
            rethrow: false,
            handler: function() {
              return cb(util.right(void 0));
            }
          })();
          switch (status) {
            case SUSPENDED:
              interrupt = util.left(error4);
              status = COMPLETED;
              step4 = interrupt;
              run3(runTick);
              break;
            case PENDING:
              if (interrupt === null) {
                interrupt = util.left(error4);
              }
              if (bracketCount === 0) {
                if (status === PENDING) {
                  attempts = new Aff2(CONS, new Aff2(FINALIZER, step4(error4)), attempts, interrupt);
                }
                status = RETURN;
                step4 = null;
                fail2 = null;
                run3(++runTick);
              }
              break;
            default:
              if (interrupt === null) {
                interrupt = util.left(error4);
              }
              if (bracketCount === 0) {
                status = RETURN;
                step4 = null;
                fail2 = null;
              }
          }
          return canceler;
        };
      }
      function join3(cb) {
        return function() {
          var canceler = onComplete({
            rethrow: false,
            handler: cb
          })();
          if (status === SUSPENDED) {
            run3(runTick);
          }
          return canceler;
        };
      }
      return {
        kill: kill2,
        join: join3,
        onComplete,
        isSuspended: function() {
          return status === SUSPENDED;
        },
        run: function() {
          if (status === SUSPENDED) {
            if (!Scheduler.isDraining()) {
              Scheduler.enqueue(function() {
                run3(runTick);
              });
            } else {
              run3(runTick);
            }
          }
        }
      };
    }
    function runPar(util, supervisor, par, cb) {
      var fiberId = 0;
      var fibers = {};
      var killId = 0;
      var kills = {};
      var early = new Error("[ParAff] Early exit");
      var interrupt = null;
      var root2 = EMPTY;
      function kill2(error4, par2, cb2) {
        var step4 = par2;
        var head3 = null;
        var tail = null;
        var count = 0;
        var kills2 = {};
        var tmp, kid;
        loop: while (true) {
          tmp = null;
          switch (step4.tag) {
            case FORKED:
              if (step4._3 === EMPTY) {
                tmp = fibers[step4._1];
                kills2[count++] = tmp.kill(error4, function(result) {
                  return function() {
                    count--;
                    if (count === 0) {
                      cb2(result)();
                    }
                  };
                });
              }
              if (head3 === null) {
                break loop;
              }
              step4 = head3._2;
              if (tail === null) {
                head3 = null;
              } else {
                head3 = tail._1;
                tail = tail._2;
              }
              break;
            case MAP:
              step4 = step4._2;
              break;
            case APPLY:
            case ALT:
              if (head3) {
                tail = new Aff2(CONS, head3, tail);
              }
              head3 = step4;
              step4 = step4._1;
              break;
          }
        }
        if (count === 0) {
          cb2(util.right(void 0))();
        } else {
          kid = 0;
          tmp = count;
          for (; kid < tmp; kid++) {
            kills2[kid] = kills2[kid]();
          }
        }
        return kills2;
      }
      function join3(result, head3, tail) {
        var fail2, step4, lhs, rhs, tmp, kid;
        if (util.isLeft(result)) {
          fail2 = result;
          step4 = null;
        } else {
          step4 = result;
          fail2 = null;
        }
        loop: while (true) {
          lhs = null;
          rhs = null;
          tmp = null;
          kid = null;
          if (interrupt !== null) {
            return;
          }
          if (head3 === null) {
            cb(fail2 || step4)();
            return;
          }
          if (head3._3 !== EMPTY) {
            return;
          }
          switch (head3.tag) {
            case MAP:
              if (fail2 === null) {
                head3._3 = util.right(head3._1(util.fromRight(step4)));
                step4 = head3._3;
              } else {
                head3._3 = fail2;
              }
              break;
            case APPLY:
              lhs = head3._1._3;
              rhs = head3._2._3;
              if (fail2) {
                head3._3 = fail2;
                tmp = true;
                kid = killId++;
                kills[kid] = kill2(early, fail2 === lhs ? head3._2 : head3._1, function() {
                  return function() {
                    delete kills[kid];
                    if (tmp) {
                      tmp = false;
                    } else if (tail === null) {
                      join3(fail2, null, null);
                    } else {
                      join3(fail2, tail._1, tail._2);
                    }
                  };
                });
                if (tmp) {
                  tmp = false;
                  return;
                }
              } else if (lhs === EMPTY || rhs === EMPTY) {
                return;
              } else {
                step4 = util.right(util.fromRight(lhs)(util.fromRight(rhs)));
                head3._3 = step4;
              }
              break;
            case ALT:
              lhs = head3._1._3;
              rhs = head3._2._3;
              if (lhs === EMPTY && util.isLeft(rhs) || rhs === EMPTY && util.isLeft(lhs)) {
                return;
              }
              if (lhs !== EMPTY && util.isLeft(lhs) && rhs !== EMPTY && util.isLeft(rhs)) {
                fail2 = step4 === lhs ? rhs : lhs;
                step4 = null;
                head3._3 = fail2;
              } else {
                head3._3 = step4;
                tmp = true;
                kid = killId++;
                kills[kid] = kill2(early, step4 === lhs ? head3._2 : head3._1, function() {
                  return function() {
                    delete kills[kid];
                    if (tmp) {
                      tmp = false;
                    } else if (tail === null) {
                      join3(step4, null, null);
                    } else {
                      join3(step4, tail._1, tail._2);
                    }
                  };
                });
                if (tmp) {
                  tmp = false;
                  return;
                }
              }
              break;
          }
          if (tail === null) {
            head3 = null;
          } else {
            head3 = tail._1;
            tail = tail._2;
          }
        }
      }
      function resolve(fiber) {
        return function(result) {
          return function() {
            delete fibers[fiber._1];
            fiber._3 = result;
            join3(result, fiber._2._1, fiber._2._2);
          };
        };
      }
      function run3() {
        var status = CONTINUE;
        var step4 = par;
        var head3 = null;
        var tail = null;
        var tmp, fid;
        loop: while (true) {
          tmp = null;
          fid = null;
          switch (status) {
            case CONTINUE:
              switch (step4.tag) {
                case MAP:
                  if (head3) {
                    tail = new Aff2(CONS, head3, tail);
                  }
                  head3 = new Aff2(MAP, step4._1, EMPTY, EMPTY);
                  step4 = step4._2;
                  break;
                case APPLY:
                  if (head3) {
                    tail = new Aff2(CONS, head3, tail);
                  }
                  head3 = new Aff2(APPLY, EMPTY, step4._2, EMPTY);
                  step4 = step4._1;
                  break;
                case ALT:
                  if (head3) {
                    tail = new Aff2(CONS, head3, tail);
                  }
                  head3 = new Aff2(ALT, EMPTY, step4._2, EMPTY);
                  step4 = step4._1;
                  break;
                default:
                  fid = fiberId++;
                  status = RETURN;
                  tmp = step4;
                  step4 = new Aff2(FORKED, fid, new Aff2(CONS, head3, tail), EMPTY);
                  tmp = Fiber(util, supervisor, tmp);
                  tmp.onComplete({
                    rethrow: false,
                    handler: resolve(step4)
                  })();
                  fibers[fid] = tmp;
                  if (supervisor) {
                    supervisor.register(tmp);
                  }
              }
              break;
            case RETURN:
              if (head3 === null) {
                break loop;
              }
              if (head3._1 === EMPTY) {
                head3._1 = step4;
                status = CONTINUE;
                step4 = head3._2;
                head3._2 = EMPTY;
              } else {
                head3._2 = step4;
                step4 = head3;
                if (tail === null) {
                  head3 = null;
                } else {
                  head3 = tail._1;
                  tail = tail._2;
                }
              }
          }
        }
        root2 = step4;
        for (fid = 0; fid < fiberId; fid++) {
          fibers[fid].run();
        }
      }
      function cancel(error4, cb2) {
        interrupt = util.left(error4);
        var innerKills;
        for (var kid in kills) {
          if (kills.hasOwnProperty(kid)) {
            innerKills = kills[kid];
            for (kid in innerKills) {
              if (innerKills.hasOwnProperty(kid)) {
                innerKills[kid]();
              }
            }
          }
        }
        kills = null;
        var newKills = kill2(error4, root2, cb2);
        return function(killError) {
          return new Aff2(ASYNC, function(killCb) {
            return function() {
              for (var kid2 in newKills) {
                if (newKills.hasOwnProperty(kid2)) {
                  newKills[kid2]();
                }
              }
              return nonCanceler2;
            };
          });
        };
      }
      run3();
      return function(killError) {
        return new Aff2(ASYNC, function(killCb) {
          return function() {
            return cancel(killError, killCb);
          };
        });
      };
    }
    function sequential3(util, supervisor, par) {
      return new Aff2(ASYNC, function(cb) {
        return function() {
          return runPar(util, supervisor, par, cb);
        };
      });
    }
    Aff2.EMPTY = EMPTY;
    Aff2.Pure = AffCtr(PURE);
    Aff2.Throw = AffCtr(THROW);
    Aff2.Catch = AffCtr(CATCH);
    Aff2.Sync = AffCtr(SYNC);
    Aff2.Async = AffCtr(ASYNC);
    Aff2.Bind = AffCtr(BIND);
    Aff2.Bracket = AffCtr(BRACKET);
    Aff2.Fork = AffCtr(FORK);
    Aff2.Seq = AffCtr(SEQ);
    Aff2.ParMap = AffCtr(MAP);
    Aff2.ParApply = AffCtr(APPLY);
    Aff2.ParAlt = AffCtr(ALT);
    Aff2.Fiber = Fiber;
    Aff2.Supervisor = Supervisor;
    Aff2.Scheduler = Scheduler;
    Aff2.nonCanceler = nonCanceler2;
    return Aff2;
  }();
  var _pure = Aff.Pure;
  var _throwError = Aff.Throw;
  function _catchError(aff) {
    return function(k) {
      return Aff.Catch(aff, k);
    };
  }
  function _map(f) {
    return function(aff) {
      if (aff.tag === Aff.Pure.tag) {
        return Aff.Pure(f(aff._1));
      } else {
        return Aff.Bind(aff, function(value12) {
          return Aff.Pure(f(value12));
        });
      }
    };
  }
  function _bind(aff) {
    return function(k) {
      return Aff.Bind(aff, k);
    };
  }
  function _fork(immediate) {
    return function(aff) {
      return Aff.Fork(immediate, aff);
    };
  }
  var _liftEffect = Aff.Sync;
  function _parAffMap(f) {
    return function(aff) {
      return Aff.ParMap(f, aff);
    };
  }
  function _parAffApply(aff1) {
    return function(aff2) {
      return Aff.ParApply(aff1, aff2);
    };
  }
  var makeAff = Aff.Async;
  function generalBracket(acquire) {
    return function(options2) {
      return function(k) {
        return Aff.Bracket(acquire, options2, k);
      };
    };
  }
  function _makeFiber(util, aff) {
    return function() {
      return Aff.Fiber(util, null, aff);
    };
  }
  var _sequential = Aff.Seq;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Exception/foreign.js
  function error(msg) {
    return new Error(msg);
  }
  function throwException(e) {
    return function() {
      throw e;
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Exception/index.js
  var $$throw = function($4) {
    return throwException(error($4));
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Monad.Error.Class/index.js
  var catchError = function(dict) {
    return dict.catchError;
  };
  var $$try = function(dictMonadError) {
    var catchError1 = catchError(dictMonadError);
    var Monad0 = dictMonadError.MonadThrow0().Monad0();
    var map36 = map(Monad0.Bind1().Apply0().Functor0());
    var pure21 = pure(Monad0.Applicative0());
    return function(a2) {
      return catchError1(map36(Right.create)(a2))(function($52) {
        return pure21(Left.create($52));
      });
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Monad.State.Class/index.js
  var state = function(dict) {
    return dict.state;
  };
  var modify_2 = function(dictMonadState) {
    var state1 = state(dictMonadState);
    return function(f) {
      return state1(function(s) {
        return new Tuple(unit, f(s));
      });
    };
  };
  var get = function(dictMonadState) {
    return state(dictMonadState)(function(s) {
      return new Tuple(s, s);
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Class/index.js
  var monadEffectEffect = {
    liftEffect: /* @__PURE__ */ identity(categoryFn),
    Monad0: function() {
      return monadEffect;
    }
  };
  var liftEffect = function(dict) {
    return dict.liftEffect;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Parallel.Class/index.js
  var sequential = function(dict) {
    return dict.sequential;
  };
  var parallel = function(dict) {
    return dict.parallel;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Parallel/index.js
  var identity5 = /* @__PURE__ */ identity(categoryFn);
  var parTraverse_ = function(dictParallel) {
    var sequential3 = sequential(dictParallel);
    var parallel4 = parallel(dictParallel);
    return function(dictApplicative) {
      var traverse_17 = traverse_(dictApplicative);
      return function(dictFoldable) {
        var traverse_18 = traverse_17(dictFoldable);
        return function(f) {
          var $51 = traverse_18(function($53) {
            return parallel4(f($53));
          });
          return function($52) {
            return sequential3($51($52));
          };
        };
      };
    };
  };
  var parSequence_ = function(dictParallel) {
    var parTraverse_1 = parTraverse_(dictParallel);
    return function(dictApplicative) {
      var parTraverse_2 = parTraverse_1(dictApplicative);
      return function(dictFoldable) {
        return parTraverse_2(dictFoldable)(identity5);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Unsafe/foreign.js
  var unsafePerformEffect = function(f) {
    return f();
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Partial.Unsafe/foreign.js
  var _unsafePartial = function(f) {
    return f();
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Partial/foreign.js
  var _crashWith = function(msg) {
    throw new Error(msg);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Partial/index.js
  var crashWith = function() {
    return _crashWith;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Partial.Unsafe/index.js
  var crashWith2 = /* @__PURE__ */ crashWith();
  var unsafePartial = _unsafePartial;
  var unsafeCrashWith = function(msg) {
    return unsafePartial(function() {
      return crashWith2(msg);
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Aff/index.js
  var $runtime_lazy2 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var pure2 = /* @__PURE__ */ pure(applicativeEffect);
  var $$void3 = /* @__PURE__ */ $$void(functorEffect);
  var map6 = /* @__PURE__ */ map(functorEffect);
  var Canceler = function(x) {
    return x;
  };
  var suspendAff = /* @__PURE__ */ _fork(false);
  var functorParAff = {
    map: _parAffMap
  };
  var functorAff = {
    map: _map
  };
  var map1 = /* @__PURE__ */ map(functorAff);
  var forkAff = /* @__PURE__ */ _fork(true);
  var ffiUtil = /* @__PURE__ */ function() {
    var unsafeFromRight = function(v) {
      if (v instanceof Right) {
        return v.value0;
      }
      ;
      if (v instanceof Left) {
        return unsafeCrashWith("unsafeFromRight: Left");
      }
      ;
      throw new Error("Failed pattern match at Effect.Aff (line 412, column 21 - line 414, column 54): " + [v.constructor.name]);
    };
    var unsafeFromLeft = function(v) {
      if (v instanceof Left) {
        return v.value0;
      }
      ;
      if (v instanceof Right) {
        return unsafeCrashWith("unsafeFromLeft: Right");
      }
      ;
      throw new Error("Failed pattern match at Effect.Aff (line 407, column 20 - line 409, column 55): " + [v.constructor.name]);
    };
    var isLeft = function(v) {
      if (v instanceof Left) {
        return true;
      }
      ;
      if (v instanceof Right) {
        return false;
      }
      ;
      throw new Error("Failed pattern match at Effect.Aff (line 402, column 12 - line 404, column 21): " + [v.constructor.name]);
    };
    return {
      isLeft,
      fromLeft: unsafeFromLeft,
      fromRight: unsafeFromRight,
      left: Left.create,
      right: Right.create
    };
  }();
  var makeFiber = function(aff) {
    return _makeFiber(ffiUtil, aff);
  };
  var launchAff = function(aff) {
    return function __do12() {
      var fiber = makeFiber(aff)();
      fiber.run();
      return fiber;
    };
  };
  var bracket = function(acquire) {
    return function(completed) {
      return generalBracket(acquire)({
        killed: $$const(completed),
        failed: $$const(completed),
        completed: $$const(completed)
      });
    };
  };
  var applyParAff = {
    apply: _parAffApply,
    Functor0: function() {
      return functorParAff;
    }
  };
  var monadAff = {
    Applicative0: function() {
      return applicativeAff;
    },
    Bind1: function() {
      return bindAff;
    }
  };
  var bindAff = {
    bind: _bind,
    Apply0: function() {
      return $lazy_applyAff(0);
    }
  };
  var applicativeAff = {
    pure: _pure,
    Apply0: function() {
      return $lazy_applyAff(0);
    }
  };
  var $lazy_applyAff = /* @__PURE__ */ $runtime_lazy2("applyAff", "Effect.Aff", function() {
    return {
      apply: ap(monadAff),
      Functor0: function() {
        return functorAff;
      }
    };
  });
  var applyAff = /* @__PURE__ */ $lazy_applyAff(73);
  var pure22 = /* @__PURE__ */ pure(applicativeAff);
  var bind1 = /* @__PURE__ */ bind(bindAff);
  var bindFlipped3 = /* @__PURE__ */ bindFlipped(bindAff);
  var $$finally = function(fin) {
    return function(a2) {
      return bracket(pure22(unit))($$const(fin))($$const(a2));
    };
  };
  var parallelAff = {
    parallel: unsafeCoerce2,
    sequential: _sequential,
    Apply0: function() {
      return applyAff;
    },
    Apply1: function() {
      return applyParAff;
    }
  };
  var parallel2 = /* @__PURE__ */ parallel(parallelAff);
  var applicativeParAff = {
    pure: function($76) {
      return parallel2(pure22($76));
    },
    Apply0: function() {
      return applyParAff;
    }
  };
  var monadEffectAff = {
    liftEffect: _liftEffect,
    Monad0: function() {
      return monadAff;
    }
  };
  var liftEffect2 = /* @__PURE__ */ liftEffect(monadEffectAff);
  var effectCanceler = function($77) {
    return Canceler($$const(liftEffect2($77)));
  };
  var joinFiber = function(v) {
    return makeAff(function(k) {
      return map6(effectCanceler)(v.join(k));
    });
  };
  var functorFiber = {
    map: function(f) {
      return function(t) {
        return unsafePerformEffect(makeFiber(map1(f)(joinFiber(t))));
      };
    }
  };
  var killFiber = function(e) {
    return function(v) {
      return bind1(liftEffect2(v.isSuspended))(function(suspended) {
        if (suspended) {
          return liftEffect2($$void3(v.kill(e, $$const(pure2(unit)))));
        }
        ;
        return makeAff(function(k) {
          return map6(effectCanceler)(v.kill(e, k));
        });
      });
    };
  };
  var monadThrowAff = {
    throwError: _throwError,
    Monad0: function() {
      return monadAff;
    }
  };
  var monadErrorAff = {
    catchError: _catchError,
    MonadThrow0: function() {
      return monadThrowAff;
    }
  };
  var $$try2 = /* @__PURE__ */ $$try(monadErrorAff);
  var runAff = function(k) {
    return function(aff) {
      return launchAff(bindFlipped3(function($83) {
        return liftEffect2(k($83));
      })($$try2(aff)));
    };
  };
  var runAff_ = function(k) {
    return function(aff) {
      return $$void3(runAff(k)(aff));
    };
  };
  var monadRecAff = {
    tailRecM: function(k) {
      var go2 = function(a2) {
        return bind1(k(a2))(function(res) {
          if (res instanceof Done) {
            return pure22(res.value0);
          }
          ;
          if (res instanceof Loop) {
            return go2(res.value0);
          }
          ;
          throw new Error("Failed pattern match at Effect.Aff (line 104, column 7 - line 106, column 23): " + [res.constructor.name]);
        });
      };
      return go2;
    },
    Monad0: function() {
      return monadAff;
    }
  };
  var nonCanceler = /* @__PURE__ */ $$const(/* @__PURE__ */ pure22(unit));

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.ParentNode/foreign.js
  var getEffProp = function(name15) {
    return function(node) {
      return function() {
        return node[name15];
      };
    };
  };
  var children = getEffProp("children");
  var _firstElementChild = getEffProp("firstElementChild");
  var _lastElementChild = getEffProp("lastElementChild");
  var childElementCount = getEffProp("childElementCount");
  function _querySelector(selector) {
    return function(node) {
      return function() {
        return node.querySelector(selector);
      };
    };
  }
  function querySelectorAll(selector) {
    return function(node) {
      return function() {
        return node.querySelectorAll(selector);
      };
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Nullable/foreign.js
  var nullImpl = null;
  function nullable(a2, r, f) {
    return a2 == null ? r : f(a2);
  }
  function notNull(x) {
    return x;
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Nullable/index.js
  var toNullable = /* @__PURE__ */ maybe(nullImpl)(notNull);
  var toMaybe = function(n) {
    return nullable(n, Nothing.value, Just.create);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.ParentNode/index.js
  var map7 = /* @__PURE__ */ map(functorEffect);
  var querySelector = function(qs) {
    var $2 = map7(toMaybe);
    var $3 = _querySelector(qs);
    return function($4) {
      return $2($3($4));
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.Event.EventTarget/foreign.js
  function eventListener(fn) {
    return function() {
      return function(event) {
        return fn(event)();
      };
    };
  }
  function addEventListener(type) {
    return function(listener) {
      return function(useCapture) {
        return function(target6) {
          return function() {
            return target6.addEventListener(type, listener, useCapture);
          };
        };
      };
    };
  }
  function removeEventListener(type) {
    return function(listener) {
      return function(useCapture) {
        return function(target6) {
          return function() {
            return target6.removeEventListener(type, listener, useCapture);
          };
        };
      };
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML/foreign.js
  var windowImpl = function() {
    return window;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.Common/index.js
  var ClassName = function(x) {
    return x;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.Internal.FFI/foreign.js
  function _unsafeReadProtoTagged(nothing, just, name15, value12) {
    if (typeof window !== "undefined") {
      var ty = window[name15];
      if (ty != null && value12 instanceof ty) {
        return just(value12);
      }
    }
    var obj = value12;
    while (obj != null) {
      var proto = Object.getPrototypeOf(obj);
      var constructorName = proto.constructor.name;
      if (constructorName === name15) {
        return just(value12);
      } else if (constructorName === "Object") {
        return nothing;
      }
      obj = proto;
    }
    return nothing;
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.Internal.FFI/index.js
  var unsafeReadProtoTagged = function(name15) {
    return function(value12) {
      return _unsafeReadProtoTagged(Nothing.value, Just.create, name15, value12);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.HTMLDocument/foreign.js
  function _body(doc) {
    return doc.body;
  }
  function _readyState(doc) {
    return doc.readyState;
  }
  function _activeElement(doc) {
    return doc.activeElement;
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.HTMLDocument.ReadyState/index.js
  var Loading = /* @__PURE__ */ function() {
    function Loading2() {
    }
    ;
    Loading2.value = new Loading2();
    return Loading2;
  }();
  var Interactive = /* @__PURE__ */ function() {
    function Interactive2() {
    }
    ;
    Interactive2.value = new Interactive2();
    return Interactive2;
  }();
  var Complete = /* @__PURE__ */ function() {
    function Complete2() {
    }
    ;
    Complete2.value = new Complete2();
    return Complete2;
  }();
  var parse = function(v) {
    if (v === "loading") {
      return new Just(Loading.value);
    }
    ;
    if (v === "interactive") {
      return new Just(Interactive.value);
    }
    ;
    if (v === "complete") {
      return new Just(Complete.value);
    }
    ;
    return Nothing.value;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.HTMLDocument/index.js
  var map8 = /* @__PURE__ */ map(functorEffect);
  var toParentNode = unsafeCoerce2;
  var toEventTarget = unsafeCoerce2;
  var toDocument = unsafeCoerce2;
  var readyState = function(doc) {
    return map8(function() {
      var $4 = fromMaybe(Loading.value);
      return function($5) {
        return $4(parse($5));
      };
    }())(function() {
      return _readyState(doc);
    });
  };
  var body = function(doc) {
    return map8(toMaybe)(function() {
      return _body(doc);
    });
  };
  var activeElement = function(doc) {
    return map8(toMaybe)(function() {
      return _activeElement(doc);
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.HTMLElement/foreign.js
  function _read(nothing, just, value12) {
    var tag = Object.prototype.toString.call(value12);
    if (tag.indexOf("[object HTML") === 0 && tag.indexOf("Element]") === tag.length - 8) {
      return just(value12);
    } else {
      return nothing;
    }
  }
  function focus(elt) {
    return function() {
      return elt.focus();
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.HTMLElement/index.js
  var toParentNode2 = unsafeCoerce2;
  var toNode = unsafeCoerce2;
  var toElement = unsafeCoerce2;
  var fromNode = function(x) {
    return _read(Nothing.value, Just.create, x);
  };
  var fromElement = function(x) {
    return _read(Nothing.value, Just.create, x);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.Location/foreign.js
  function search(location2) {
    return function() {
      return location2.search;
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.Window/foreign.js
  function document(window2) {
    return function() {
      return window2.document;
    };
  }
  function location(window2) {
    return function() {
      return window2.location;
    };
  }
  function innerWidth(window2) {
    return function() {
      return window2.innerWidth;
    };
  }
  function innerHeight(window2) {
    return function() {
      return window2.innerHeight;
    };
  }
  function requestAnimationFrame(fn) {
    return function(window2) {
      return function() {
        return window2.requestAnimationFrame(fn);
      };
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.Window/index.js
  var toEventTarget2 = unsafeCoerce2;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.HTML.Event.EventTypes/index.js
  var domcontentloaded = "DOMContentLoaded";
  var blur2 = "blur";

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Aff.Util/index.js
  var bind2 = /* @__PURE__ */ bind(bindAff);
  var liftEffect3 = /* @__PURE__ */ liftEffect(monadEffectAff);
  var bindFlipped4 = /* @__PURE__ */ bindFlipped(bindEffect);
  var composeKleisliFlipped2 = /* @__PURE__ */ composeKleisliFlipped(bindEffect);
  var pure3 = /* @__PURE__ */ pure(applicativeAff);
  var bindFlipped1 = /* @__PURE__ */ bindFlipped(bindMaybe);
  var pure1 = /* @__PURE__ */ pure(applicativeEffect);
  var map9 = /* @__PURE__ */ map(functorEffect);
  var selectElement = function(query2) {
    return bind2(liftEffect3(bindFlipped4(composeKleisliFlipped2(function() {
      var $16 = querySelector(query2);
      return function($17) {
        return $16(toParentNode($17));
      };
    }())(document))(windowImpl)))(function(mel) {
      return pure3(bindFlipped1(fromElement)(mel));
    });
  };
  var runHalogenAff = /* @__PURE__ */ runAff_(/* @__PURE__ */ either(throwException)(/* @__PURE__ */ $$const(/* @__PURE__ */ pure1(unit))));
  var awaitLoad = /* @__PURE__ */ makeAff(function(callback) {
    return function __do12() {
      var rs = bindFlipped4(readyState)(bindFlipped4(document)(windowImpl))();
      if (rs instanceof Loading) {
        var et = map9(toEventTarget2)(windowImpl)();
        var listener = eventListener(function(v) {
          return callback(new Right(unit));
        })();
        addEventListener(domcontentloaded)(listener)(false)(et)();
        return effectCanceler(removeEventListener(domcontentloaded)(listener)(false)(et));
      }
      ;
      callback(new Right(unit))();
      return nonCanceler;
    };
  });

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Exists/index.js
  var runExists = unsafeCoerce2;
  var mkExists = unsafeCoerce2;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Coyoneda/index.js
  var CoyonedaF = /* @__PURE__ */ function() {
    function CoyonedaF2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    CoyonedaF2.create = function(value0) {
      return function(value1) {
        return new CoyonedaF2(value0, value1);
      };
    };
    return CoyonedaF2;
  }();
  var unCoyoneda = function(f) {
    return function(v) {
      return runExists(function(v1) {
        return f(v1.value0)(v1.value1);
      })(v);
    };
  };
  var coyoneda = function(k) {
    return function(fi) {
      return mkExists(new CoyonedaF(k, fi));
    };
  };
  var functorCoyoneda = {
    map: function(f) {
      return function(v) {
        return runExists(function(v1) {
          return coyoneda(function($180) {
            return f(v1.value0($180));
          })(v1.value1);
        })(v);
      };
    }
  };
  var liftCoyoneda = /* @__PURE__ */ coyoneda(/* @__PURE__ */ identity(categoryFn));

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.NonEmpty/index.js
  var NonEmpty = /* @__PURE__ */ function() {
    function NonEmpty2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    NonEmpty2.create = function(value0) {
      return function(value1) {
        return new NonEmpty2(value0, value1);
      };
    };
    return NonEmpty2;
  }();
  var singleton5 = function(dictPlus) {
    var empty7 = empty(dictPlus);
    return function(a2) {
      return new NonEmpty(a2, empty7);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.List.Types/index.js
  var Nil = /* @__PURE__ */ function() {
    function Nil2() {
    }
    ;
    Nil2.value = new Nil2();
    return Nil2;
  }();
  var Cons = /* @__PURE__ */ function() {
    function Cons2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Cons2.create = function(value0) {
      return function(value1) {
        return new Cons2(value0, value1);
      };
    };
    return Cons2;
  }();
  var NonEmptyList = function(x) {
    return x;
  };
  var listMap = function(f) {
    var chunkedRevMap = function($copy_v) {
      return function($copy_v1) {
        var $tco_var_v = $copy_v;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(v, v1) {
          if (v1 instanceof Cons && (v1.value1 instanceof Cons && v1.value1.value1 instanceof Cons)) {
            $tco_var_v = new Cons(v1, v);
            $copy_v1 = v1.value1.value1.value1;
            return;
          }
          ;
          var unrolledMap = function(v2) {
            if (v2 instanceof Cons && (v2.value1 instanceof Cons && v2.value1.value1 instanceof Nil)) {
              return new Cons(f(v2.value0), new Cons(f(v2.value1.value0), Nil.value));
            }
            ;
            if (v2 instanceof Cons && v2.value1 instanceof Nil) {
              return new Cons(f(v2.value0), Nil.value);
            }
            ;
            return Nil.value;
          };
          var reverseUnrolledMap = function($copy_v2) {
            return function($copy_v3) {
              var $tco_var_v2 = $copy_v2;
              var $tco_done1 = false;
              var $tco_result2;
              function $tco_loop2(v2, v3) {
                if (v2 instanceof Cons && (v2.value0 instanceof Cons && (v2.value0.value1 instanceof Cons && v2.value0.value1.value1 instanceof Cons))) {
                  $tco_var_v2 = v2.value1;
                  $copy_v3 = new Cons(f(v2.value0.value0), new Cons(f(v2.value0.value1.value0), new Cons(f(v2.value0.value1.value1.value0), v3)));
                  return;
                }
                ;
                $tco_done1 = true;
                return v3;
              }
              ;
              while (!$tco_done1) {
                $tco_result2 = $tco_loop2($tco_var_v2, $copy_v3);
              }
              ;
              return $tco_result2;
            };
          };
          $tco_done = true;
          return reverseUnrolledMap(v)(unrolledMap(v1));
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_v, $copy_v1);
        }
        ;
        return $tco_result;
      };
    };
    return chunkedRevMap(Nil.value);
  };
  var functorList = {
    map: listMap
  };
  var foldableList = {
    foldr: function(f) {
      return function(b2) {
        var rev3 = function() {
          var go2 = function($copy_v) {
            return function($copy_v1) {
              var $tco_var_v = $copy_v;
              var $tco_done = false;
              var $tco_result;
              function $tco_loop(v, v1) {
                if (v1 instanceof Nil) {
                  $tco_done = true;
                  return v;
                }
                ;
                if (v1 instanceof Cons) {
                  $tco_var_v = new Cons(v1.value0, v);
                  $copy_v1 = v1.value1;
                  return;
                }
                ;
                throw new Error("Failed pattern match at Data.List.Types (line 107, column 7 - line 107, column 23): " + [v.constructor.name, v1.constructor.name]);
              }
              ;
              while (!$tco_done) {
                $tco_result = $tco_loop($tco_var_v, $copy_v1);
              }
              ;
              return $tco_result;
            };
          };
          return go2(Nil.value);
        }();
        var $284 = foldl(foldableList)(flip(f))(b2);
        return function($285) {
          return $284(rev3($285));
        };
      };
    },
    foldl: function(f) {
      var go2 = function($copy_b) {
        return function($copy_v) {
          var $tco_var_b = $copy_b;
          var $tco_done1 = false;
          var $tco_result;
          function $tco_loop(b2, v) {
            if (v instanceof Nil) {
              $tco_done1 = true;
              return b2;
            }
            ;
            if (v instanceof Cons) {
              $tco_var_b = f(b2)(v.value0);
              $copy_v = v.value1;
              return;
            }
            ;
            throw new Error("Failed pattern match at Data.List.Types (line 111, column 12 - line 113, column 30): " + [v.constructor.name]);
          }
          ;
          while (!$tco_done1) {
            $tco_result = $tco_loop($tco_var_b, $copy_v);
          }
          ;
          return $tco_result;
        };
      };
      return go2;
    },
    foldMap: function(dictMonoid) {
      var append22 = append(dictMonoid.Semigroup0());
      var mempty2 = mempty(dictMonoid);
      return function(f) {
        return foldl(foldableList)(function(acc) {
          var $286 = append22(acc);
          return function($287) {
            return $286(f($287));
          };
        })(mempty2);
      };
    }
  };
  var foldr2 = /* @__PURE__ */ foldr(foldableList);
  var semigroupList = {
    append: function(xs) {
      return function(ys) {
        return foldr2(Cons.create)(ys)(xs);
      };
    }
  };
  var append1 = /* @__PURE__ */ append(semigroupList);
  var altList = {
    alt: append1,
    Functor0: function() {
      return functorList;
    }
  };
  var plusList = /* @__PURE__ */ function() {
    return {
      empty: Nil.value,
      Alt0: function() {
        return altList;
      }
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.Map.Internal/index.js
  var $runtime_lazy3 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var map10 = /* @__PURE__ */ map(functorMaybe);
  var Leaf = /* @__PURE__ */ function() {
    function Leaf2() {
    }
    ;
    Leaf2.value = new Leaf2();
    return Leaf2;
  }();
  var Node = /* @__PURE__ */ function() {
    function Node2(value0, value1, value22, value32, value42, value52) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
      this.value3 = value32;
      this.value4 = value42;
      this.value5 = value52;
    }
    ;
    Node2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return function(value32) {
            return function(value42) {
              return function(value52) {
                return new Node2(value0, value1, value22, value32, value42, value52);
              };
            };
          };
        };
      };
    };
    return Node2;
  }();
  var IterLeaf = /* @__PURE__ */ function() {
    function IterLeaf2() {
    }
    ;
    IterLeaf2.value = new IterLeaf2();
    return IterLeaf2;
  }();
  var IterEmit = /* @__PURE__ */ function() {
    function IterEmit2(value0, value1, value22) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
    }
    ;
    IterEmit2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return new IterEmit2(value0, value1, value22);
        };
      };
    };
    return IterEmit2;
  }();
  var IterNode = /* @__PURE__ */ function() {
    function IterNode2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    IterNode2.create = function(value0) {
      return function(value1) {
        return new IterNode2(value0, value1);
      };
    };
    return IterNode2;
  }();
  var Split = /* @__PURE__ */ function() {
    function Split2(value0, value1, value22) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
    }
    ;
    Split2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return new Split2(value0, value1, value22);
        };
      };
    };
    return Split2;
  }();
  var SplitLast = /* @__PURE__ */ function() {
    function SplitLast2(value0, value1, value22) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
    }
    ;
    SplitLast2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return new SplitLast2(value0, value1, value22);
        };
      };
    };
    return SplitLast2;
  }();
  var unsafeNode = function(k, v, l, r) {
    if (l instanceof Leaf) {
      if (r instanceof Leaf) {
        return new Node(1, 1, k, v, l, r);
      }
      ;
      if (r instanceof Node) {
        return new Node(1 + r.value0 | 0, 1 + r.value1 | 0, k, v, l, r);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 702, column 5 - line 706, column 39): " + [r.constructor.name]);
    }
    ;
    if (l instanceof Node) {
      if (r instanceof Leaf) {
        return new Node(1 + l.value0 | 0, 1 + l.value1 | 0, k, v, l, r);
      }
      ;
      if (r instanceof Node) {
        return new Node(1 + function() {
          var $280 = l.value0 > r.value0;
          if ($280) {
            return l.value0;
          }
          ;
          return r.value0;
        }() | 0, (1 + l.value1 | 0) + r.value1 | 0, k, v, l, r);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 708, column 5 - line 712, column 68): " + [r.constructor.name]);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 700, column 32 - line 712, column 68): " + [l.constructor.name]);
  };
  var toMapIter = /* @__PURE__ */ function() {
    return flip(IterNode.create)(IterLeaf.value);
  }();
  var stepWith = function(f) {
    return function(next) {
      return function(done) {
        var go2 = function($copy_v) {
          var $tco_done = false;
          var $tco_result;
          function $tco_loop(v) {
            if (v instanceof IterLeaf) {
              $tco_done = true;
              return done(unit);
            }
            ;
            if (v instanceof IterEmit) {
              $tco_done = true;
              return next(v.value0, v.value1, v.value2);
            }
            ;
            if (v instanceof IterNode) {
              $copy_v = f(v.value1)(v.value0);
              return;
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 940, column 8 - line 946, column 20): " + [v.constructor.name]);
          }
          ;
          while (!$tco_done) {
            $tco_result = $tco_loop($copy_v);
          }
          ;
          return $tco_result;
        };
        return go2;
      };
    };
  };
  var singleton6 = function(k) {
    return function(v) {
      return new Node(1, 1, k, v, Leaf.value, Leaf.value);
    };
  };
  var unsafeBalancedNode = /* @__PURE__ */ function() {
    var height8 = function(v) {
      if (v instanceof Leaf) {
        return 0;
      }
      ;
      if (v instanceof Node) {
        return v.value0;
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 757, column 12 - line 759, column 26): " + [v.constructor.name]);
    };
    var rotateLeft = function(k, v, l, rk, rv, rl, rr) {
      if (rl instanceof Node && rl.value0 > height8(rr)) {
        return unsafeNode(rl.value2, rl.value3, unsafeNode(k, v, l, rl.value4), unsafeNode(rk, rv, rl.value5, rr));
      }
      ;
      return unsafeNode(rk, rv, unsafeNode(k, v, l, rl), rr);
    };
    var rotateRight = function(k, v, lk, lv, ll, lr, r) {
      if (lr instanceof Node && height8(ll) <= lr.value0) {
        return unsafeNode(lr.value2, lr.value3, unsafeNode(lk, lv, ll, lr.value4), unsafeNode(k, v, lr.value5, r));
      }
      ;
      return unsafeNode(lk, lv, ll, unsafeNode(k, v, lr, r));
    };
    return function(k, v, l, r) {
      if (l instanceof Leaf) {
        if (r instanceof Leaf) {
          return singleton6(k)(v);
        }
        ;
        if (r instanceof Node && r.value0 > 1) {
          return rotateLeft(k, v, l, r.value2, r.value3, r.value4, r.value5);
        }
        ;
        return unsafeNode(k, v, l, r);
      }
      ;
      if (l instanceof Node) {
        if (r instanceof Node) {
          if (r.value0 > (l.value0 + 1 | 0)) {
            return rotateLeft(k, v, l, r.value2, r.value3, r.value4, r.value5);
          }
          ;
          if (l.value0 > (r.value0 + 1 | 0)) {
            return rotateRight(k, v, l.value2, l.value3, l.value4, l.value5, r);
          }
          ;
        }
        ;
        if (r instanceof Leaf && l.value0 > 1) {
          return rotateRight(k, v, l.value2, l.value3, l.value4, l.value5, r);
        }
        ;
        return unsafeNode(k, v, l, r);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 717, column 40 - line 738, column 34): " + [l.constructor.name]);
    };
  }();
  var $lazy_unsafeSplit = /* @__PURE__ */ $runtime_lazy3("unsafeSplit", "Data.Map.Internal", function() {
    return function(comp, k, m) {
      if (m instanceof Leaf) {
        return new Split(Nothing.value, Leaf.value, Leaf.value);
      }
      ;
      if (m instanceof Node) {
        var v = comp(k)(m.value2);
        if (v instanceof LT) {
          var v1 = $lazy_unsafeSplit(793)(comp, k, m.value4);
          return new Split(v1.value0, v1.value1, unsafeBalancedNode(m.value2, m.value3, v1.value2, m.value5));
        }
        ;
        if (v instanceof GT) {
          var v1 = $lazy_unsafeSplit(796)(comp, k, m.value5);
          return new Split(v1.value0, unsafeBalancedNode(m.value2, m.value3, m.value4, v1.value1), v1.value2);
        }
        ;
        if (v instanceof EQ) {
          return new Split(new Just(m.value3), m.value4, m.value5);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 791, column 5 - line 799, column 30): " + [v.constructor.name]);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 787, column 34 - line 799, column 30): " + [m.constructor.name]);
    };
  });
  var unsafeSplit = /* @__PURE__ */ $lazy_unsafeSplit(786);
  var $lazy_unsafeSplitLast = /* @__PURE__ */ $runtime_lazy3("unsafeSplitLast", "Data.Map.Internal", function() {
    return function(k, v, l, r) {
      if (r instanceof Leaf) {
        return new SplitLast(k, v, l);
      }
      ;
      if (r instanceof Node) {
        var v1 = $lazy_unsafeSplitLast(779)(r.value2, r.value3, r.value4, r.value5);
        return new SplitLast(v1.value0, v1.value1, unsafeBalancedNode(k, v, l, v1.value2));
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 776, column 37 - line 780, column 57): " + [r.constructor.name]);
    };
  });
  var unsafeSplitLast = /* @__PURE__ */ $lazy_unsafeSplitLast(775);
  var unsafeJoinNodes = function(v, v1) {
    if (v instanceof Leaf) {
      return v1;
    }
    ;
    if (v instanceof Node) {
      var v2 = unsafeSplitLast(v.value2, v.value3, v.value4, v.value5);
      return unsafeBalancedNode(v2.value0, v2.value1, v2.value2, v1);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 764, column 25 - line 768, column 38): " + [v.constructor.name, v1.constructor.name]);
  };
  var pop = function(dictOrd) {
    var compare2 = compare(dictOrd);
    return function(k) {
      return function(m) {
        var v = unsafeSplit(compare2, k, m);
        return map10(function(a2) {
          return new Tuple(a2, unsafeJoinNodes(v.value1, v.value2));
        })(v.value0);
      };
    };
  };
  var lookup = function(dictOrd) {
    var compare2 = compare(dictOrd);
    return function(k) {
      var go2 = function($copy_v) {
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(v) {
          if (v instanceof Leaf) {
            $tco_done = true;
            return Nothing.value;
          }
          ;
          if (v instanceof Node) {
            var v1 = compare2(k)(v.value2);
            if (v1 instanceof LT) {
              $copy_v = v.value4;
              return;
            }
            ;
            if (v1 instanceof GT) {
              $copy_v = v.value5;
              return;
            }
            ;
            if (v1 instanceof EQ) {
              $tco_done = true;
              return new Just(v.value3);
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 283, column 7 - line 286, column 22): " + [v1.constructor.name]);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 280, column 8 - line 286, column 22): " + [v.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($copy_v);
        }
        ;
        return $tco_result;
      };
      return go2;
    };
  };
  var iterMapL = /* @__PURE__ */ function() {
    var go2 = function($copy_iter) {
      return function($copy_v) {
        var $tco_var_iter = $copy_iter;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(iter, v) {
          if (v instanceof Leaf) {
            $tco_done = true;
            return iter;
          }
          ;
          if (v instanceof Node) {
            if (v.value5 instanceof Leaf) {
              $tco_var_iter = new IterEmit(v.value2, v.value3, iter);
              $copy_v = v.value4;
              return;
            }
            ;
            $tco_var_iter = new IterEmit(v.value2, v.value3, new IterNode(v.value5, iter));
            $copy_v = v.value4;
            return;
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 951, column 13 - line 958, column 48): " + [v.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_iter, $copy_v);
        }
        ;
        return $tco_result;
      };
    };
    return go2;
  }();
  var stepAscCps = /* @__PURE__ */ stepWith(iterMapL);
  var stepUnfoldr = /* @__PURE__ */ function() {
    var step4 = function(k, v, next) {
      return new Just(new Tuple(new Tuple(k, v), next));
    };
    return stepAscCps(step4)(function(v) {
      return Nothing.value;
    });
  }();
  var toUnfoldable = function(dictUnfoldable) {
    var $784 = unfoldr(dictUnfoldable)(stepUnfoldr);
    return function($785) {
      return $784(toMapIter($785));
    };
  };
  var insert = function(dictOrd) {
    var compare2 = compare(dictOrd);
    return function(k) {
      return function(v) {
        var go2 = function(v1) {
          if (v1 instanceof Leaf) {
            return singleton6(k)(v);
          }
          ;
          if (v1 instanceof Node) {
            var v2 = compare2(k)(v1.value2);
            if (v2 instanceof LT) {
              return unsafeBalancedNode(v1.value2, v1.value3, go2(v1.value4), v1.value5);
            }
            ;
            if (v2 instanceof GT) {
              return unsafeBalancedNode(v1.value2, v1.value3, v1.value4, go2(v1.value5));
            }
            ;
            if (v2 instanceof EQ) {
              return new Node(v1.value0, v1.value1, k, v, v1.value4, v1.value5);
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 471, column 7 - line 474, column 35): " + [v2.constructor.name]);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 468, column 8 - line 474, column 35): " + [v1.constructor.name]);
        };
        return go2;
      };
    };
  };
  var foldableMap = {
    foldr: function(f) {
      return function(z) {
        var $lazy_go = $runtime_lazy3("go", "Data.Map.Internal", function() {
          return function(m$prime, z$prime) {
            if (m$prime instanceof Leaf) {
              return z$prime;
            }
            ;
            if (m$prime instanceof Node) {
              return $lazy_go(172)(m$prime.value4, f(m$prime.value3)($lazy_go(172)(m$prime.value5, z$prime)));
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 169, column 26 - line 172, column 43): " + [m$prime.constructor.name]);
          };
        });
        var go2 = $lazy_go(169);
        return function(m) {
          return go2(m, z);
        };
      };
    },
    foldl: function(f) {
      return function(z) {
        var $lazy_go = $runtime_lazy3("go", "Data.Map.Internal", function() {
          return function(z$prime, m$prime) {
            if (m$prime instanceof Leaf) {
              return z$prime;
            }
            ;
            if (m$prime instanceof Node) {
              return $lazy_go(178)(f($lazy_go(178)(z$prime, m$prime.value4))(m$prime.value3), m$prime.value5);
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 175, column 26 - line 178, column 43): " + [m$prime.constructor.name]);
          };
        });
        var go2 = $lazy_go(175);
        return function(m) {
          return go2(z, m);
        };
      };
    },
    foldMap: function(dictMonoid) {
      var mempty2 = mempty(dictMonoid);
      var append110 = append(dictMonoid.Semigroup0());
      return function(f) {
        var go2 = function(v) {
          if (v instanceof Leaf) {
            return mempty2;
          }
          ;
          if (v instanceof Node) {
            return append110(go2(v.value4))(append110(f(v.value3))(go2(v.value5)));
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 181, column 10 - line 184, column 28): " + [v.constructor.name]);
        };
        return go2;
      };
    }
  };
  var empty2 = /* @__PURE__ */ function() {
    return Leaf.value;
  }();
  var $$delete = function(dictOrd) {
    var compare2 = compare(dictOrd);
    return function(k) {
      var go2 = function(v) {
        if (v instanceof Leaf) {
          return Leaf.value;
        }
        ;
        if (v instanceof Node) {
          var v1 = compare2(k)(v.value2);
          if (v1 instanceof LT) {
            return unsafeBalancedNode(v.value2, v.value3, go2(v.value4), v.value5);
          }
          ;
          if (v1 instanceof GT) {
            return unsafeBalancedNode(v.value2, v.value3, v.value4, go2(v.value5));
          }
          ;
          if (v1 instanceof EQ) {
            return unsafeJoinNodes(v.value4, v.value5);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 498, column 7 - line 501, column 43): " + [v1.constructor.name]);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 495, column 8 - line 501, column 43): " + [v.constructor.name]);
      };
      return go2;
    };
  };
  var alter = function(dictOrd) {
    var compare2 = compare(dictOrd);
    return function(f) {
      return function(k) {
        return function(m) {
          var v = unsafeSplit(compare2, k, m);
          var v2 = f(v.value0);
          if (v2 instanceof Nothing) {
            return unsafeJoinNodes(v.value1, v.value2);
          }
          ;
          if (v2 instanceof Just) {
            return unsafeBalancedNode(k, v2.value0, v.value1, v.value2);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 514, column 3 - line 518, column 41): " + [v2.constructor.name]);
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Data.OrdBox/index.js
  var OrdBox = /* @__PURE__ */ function() {
    function OrdBox2(value0, value1, value22) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
    }
    ;
    OrdBox2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return new OrdBox2(value0, value1, value22);
        };
      };
    };
    return OrdBox2;
  }();
  var mkOrdBox = function(dictOrd) {
    return OrdBox.create(eq(dictOrd.Eq0()))(compare(dictOrd));
  };
  var eqOrdBox = {
    eq: function(v) {
      return function(v1) {
        return v.value0(v.value2)(v1.value2);
      };
    }
  };
  var ordOrdBox = {
    compare: function(v) {
      return function(v1) {
        return v.value1(v.value2)(v1.value2);
      };
    },
    Eq0: function() {
      return eqOrdBox;
    }
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Data.Slot/index.js
  var ordTuple2 = /* @__PURE__ */ ordTuple(ordString)(ordOrdBox);
  var pop1 = /* @__PURE__ */ pop(ordTuple2);
  var lookup1 = /* @__PURE__ */ lookup(ordTuple2);
  var insert1 = /* @__PURE__ */ insert(ordTuple2);
  var pop2 = function() {
    return function(dictIsSymbol) {
      var reflectSymbol2 = reflectSymbol(dictIsSymbol);
      return function(dictOrd) {
        var mkOrdBox2 = mkOrdBox(dictOrd);
        return function(sym) {
          return function(key2) {
            return function(v) {
              return pop1(new Tuple(reflectSymbol2(sym), mkOrdBox2(key2)))(v);
            };
          };
        };
      };
    };
  };
  var lookup2 = function() {
    return function(dictIsSymbol) {
      var reflectSymbol2 = reflectSymbol(dictIsSymbol);
      return function(dictOrd) {
        var mkOrdBox2 = mkOrdBox(dictOrd);
        return function(sym) {
          return function(key2) {
            return function(v) {
              return lookup1(new Tuple(reflectSymbol2(sym), mkOrdBox2(key2)))(v);
            };
          };
        };
      };
    };
  };
  var insert2 = function() {
    return function(dictIsSymbol) {
      var reflectSymbol2 = reflectSymbol(dictIsSymbol);
      return function(dictOrd) {
        var mkOrdBox2 = mkOrdBox(dictOrd);
        return function(sym) {
          return function(key2) {
            return function(val) {
              return function(v) {
                return insert1(new Tuple(reflectSymbol2(sym), mkOrdBox2(key2)))(val)(v);
              };
            };
          };
        };
      };
    };
  };
  var foreachSlot = function(dictApplicative) {
    var traverse_17 = traverse_(dictApplicative)(foldableMap);
    return function(v) {
      return function(k) {
        return traverse_17(function($54) {
          return k($54);
        })(v);
      };
    };
  };
  var empty3 = empty2;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/DOM.HTML.Indexed.ButtonType/index.js
  var ButtonButton = /* @__PURE__ */ function() {
    function ButtonButton2() {
    }
    ;
    ButtonButton2.value = new ButtonButton2();
    return ButtonButton2;
  }();
  var ButtonSubmit = /* @__PURE__ */ function() {
    function ButtonSubmit2() {
    }
    ;
    ButtonSubmit2.value = new ButtonSubmit2();
    return ButtonSubmit2;
  }();
  var ButtonReset = /* @__PURE__ */ function() {
    function ButtonReset2() {
    }
    ;
    ButtonReset2.value = new ButtonReset2();
    return ButtonReset2;
  }();
  var renderButtonType = function(v) {
    if (v instanceof ButtonButton) {
      return "button";
    }
    ;
    if (v instanceof ButtonSubmit) {
      return "submit";
    }
    ;
    if (v instanceof ButtonReset) {
      return "reset";
    }
    ;
    throw new Error("Failed pattern match at DOM.HTML.Indexed.ButtonType (line 14, column 20 - line 17, column 25): " + [v.constructor.name]);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Query.Input/index.js
  var RefUpdate = /* @__PURE__ */ function() {
    function RefUpdate2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    RefUpdate2.create = function(value0) {
      return function(value1) {
        return new RefUpdate2(value0, value1);
      };
    };
    return RefUpdate2;
  }();
  var Action = /* @__PURE__ */ function() {
    function Action3(value0) {
      this.value0 = value0;
    }
    ;
    Action3.create = function(value0) {
      return new Action3(value0);
    };
    return Action3;
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.Machine/index.js
  var Step = /* @__PURE__ */ function() {
    function Step3(value0, value1, value22, value32) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
      this.value3 = value32;
    }
    ;
    Step3.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return function(value32) {
            return new Step3(value0, value1, value22, value32);
          };
        };
      };
    };
    return Step3;
  }();
  var unStep = unsafeCoerce2;
  var step2 = function(v, a2) {
    return v.value2(v.value1, a2);
  };
  var mkStep = unsafeCoerce2;
  var halt = function(v) {
    return v.value3(v.value1);
  };
  var extract2 = /* @__PURE__ */ unStep(function(v) {
    return v.value0;
  });

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.Types/index.js
  var map11 = /* @__PURE__ */ map(functorArray);
  var map12 = /* @__PURE__ */ map(functorTuple);
  var Text = /* @__PURE__ */ function() {
    function Text2(value0) {
      this.value0 = value0;
    }
    ;
    Text2.create = function(value0) {
      return new Text2(value0);
    };
    return Text2;
  }();
  var Elem = /* @__PURE__ */ function() {
    function Elem2(value0, value1, value22, value32) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
      this.value3 = value32;
    }
    ;
    Elem2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return function(value32) {
            return new Elem2(value0, value1, value22, value32);
          };
        };
      };
    };
    return Elem2;
  }();
  var Keyed = /* @__PURE__ */ function() {
    function Keyed2(value0, value1, value22, value32) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
      this.value3 = value32;
    }
    ;
    Keyed2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return function(value32) {
            return new Keyed2(value0, value1, value22, value32);
          };
        };
      };
    };
    return Keyed2;
  }();
  var Widget = /* @__PURE__ */ function() {
    function Widget2(value0) {
      this.value0 = value0;
    }
    ;
    Widget2.create = function(value0) {
      return new Widget2(value0);
    };
    return Widget2;
  }();
  var Grafted = /* @__PURE__ */ function() {
    function Grafted2(value0) {
      this.value0 = value0;
    }
    ;
    Grafted2.create = function(value0) {
      return new Grafted2(value0);
    };
    return Grafted2;
  }();
  var Graft = /* @__PURE__ */ function() {
    function Graft2(value0, value1, value22) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
    }
    ;
    Graft2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return new Graft2(value0, value1, value22);
        };
      };
    };
    return Graft2;
  }();
  var unGraft = function(f) {
    return function($61) {
      return f($61);
    };
  };
  var graft = unsafeCoerce2;
  var bifunctorGraft = {
    bimap: function(f) {
      return function(g) {
        return unGraft(function(v) {
          return graft(new Graft(function($63) {
            return f(v.value0($63));
          }, function($64) {
            return g(v.value1($64));
          }, v.value2));
        });
      };
    }
  };
  var bimap2 = /* @__PURE__ */ bimap(bifunctorGraft);
  var runGraft = /* @__PURE__ */ unGraft(function(v) {
    var go2 = function(v2) {
      if (v2 instanceof Text) {
        return new Text(v2.value0);
      }
      ;
      if (v2 instanceof Elem) {
        return new Elem(v2.value0, v2.value1, v.value0(v2.value2), map11(go2)(v2.value3));
      }
      ;
      if (v2 instanceof Keyed) {
        return new Keyed(v2.value0, v2.value1, v.value0(v2.value2), map11(map12(go2))(v2.value3));
      }
      ;
      if (v2 instanceof Widget) {
        return new Widget(v.value1(v2.value0));
      }
      ;
      if (v2 instanceof Grafted) {
        return new Grafted(bimap2(v.value0)(v.value1)(v2.value0));
      }
      ;
      throw new Error("Failed pattern match at Halogen.VDom.Types (line 86, column 7 - line 86, column 27): " + [v2.constructor.name]);
    };
    return go2(v.value2);
  });

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.Util/foreign.js
  function unsafeGetAny(key2, obj) {
    return obj[key2];
  }
  function unsafeHasAny(key2, obj) {
    return obj.hasOwnProperty(key2);
  }
  function unsafeSetAny(key2, val, obj) {
    obj[key2] = val;
  }
  function forE2(a2, f) {
    var b2 = [];
    for (var i2 = 0; i2 < a2.length; i2++) {
      b2.push(f(i2, a2[i2]));
    }
    return b2;
  }
  function forEachE(a2, f) {
    for (var i2 = 0; i2 < a2.length; i2++) {
      f(a2[i2]);
    }
  }
  function forInE(o, f) {
    var ks = Object.keys(o);
    for (var i2 = 0; i2 < ks.length; i2++) {
      var k = ks[i2];
      f(k, o[k]);
    }
  }
  function diffWithIxE(a1, a2, f1, f2, f3) {
    var a3 = [];
    var l1 = a1.length;
    var l2 = a2.length;
    var i2 = 0;
    while (1) {
      if (i2 < l1) {
        if (i2 < l2) {
          a3.push(f1(i2, a1[i2], a2[i2]));
        } else {
          f2(i2, a1[i2]);
        }
      } else if (i2 < l2) {
        a3.push(f3(i2, a2[i2]));
      } else {
        break;
      }
      i2++;
    }
    return a3;
  }
  function strMapWithIxE(as, fk, f) {
    var o = {};
    for (var i2 = 0; i2 < as.length; i2++) {
      var a2 = as[i2];
      var k = fk(a2);
      o[k] = f(k, i2, a2);
    }
    return o;
  }
  function diffWithKeyAndIxE(o1, as, fk, f1, f2, f3) {
    var o2 = {};
    for (var i2 = 0; i2 < as.length; i2++) {
      var a2 = as[i2];
      var k = fk(a2);
      if (o1.hasOwnProperty(k)) {
        o2[k] = f1(k, i2, o1[k], a2);
      } else {
        o2[k] = f3(k, i2, a2);
      }
    }
    for (var k in o1) {
      if (k in o2) {
        continue;
      }
      f2(k, o1[k]);
    }
    return o2;
  }
  function refEq2(a2, b2) {
    return a2 === b2;
  }
  function createTextNode(s, doc) {
    return doc.createTextNode(s);
  }
  function setTextContent(s, n) {
    n.textContent = s;
  }
  function createElement(ns, name15, doc) {
    if (ns != null) {
      return doc.createElementNS(ns, name15);
    } else {
      return doc.createElement(name15);
    }
  }
  function insertChildIx(i2, a2, b2) {
    var n = b2.childNodes.item(i2) || null;
    if (n !== a2) {
      b2.insertBefore(a2, n);
    }
  }
  function removeChild(a2, b2) {
    if (b2 && a2.parentNode === b2) {
      b2.removeChild(a2);
    }
  }
  function parentNode(a2) {
    return a2.parentNode;
  }
  function setAttribute(ns, attr3, val, el2) {
    if (ns != null) {
      el2.setAttributeNS(ns, attr3, val);
    } else {
      el2.setAttribute(attr3, val);
    }
  }
  function removeAttribute(ns, attr3, el2) {
    if (ns != null) {
      el2.removeAttributeNS(ns, attr3);
    } else {
      el2.removeAttribute(attr3);
    }
  }
  function hasAttribute(ns, attr3, el2) {
    if (ns != null) {
      return el2.hasAttributeNS(ns, attr3);
    } else {
      return el2.hasAttribute(attr3);
    }
  }
  function addEventListener2(ev, listener, el2) {
    el2.addEventListener(ev, listener, false);
  }
  function removeEventListener2(ev, listener, el2) {
    el2.removeEventListener(ev, listener, false);
  }
  var jsUndefined = void 0;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Foreign.Object.ST/foreign.js
  var newImpl = function() {
    return {};
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.Util/index.js
  var unsafeLookup = unsafeGetAny;
  var unsafeFreeze2 = unsafeCoerce2;
  var pokeMutMap = unsafeSetAny;
  var newMutMap = newImpl;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.Element/foreign.js
  var getProp = function(name15) {
    return function(doctype) {
      return doctype[name15];
    };
  };
  var _namespaceURI = getProp("namespaceURI");
  var _prefix = getProp("prefix");
  var localName = getProp("localName");
  var tagName = getProp("tagName");
  function setAttribute2(name15) {
    return function(value12) {
      return function(element3) {
        return function() {
          element3.setAttribute(name15, value12);
        };
      };
    };
  }
  function _getAttribute(name15) {
    return function(element3) {
      return function() {
        return element3.getAttribute(name15);
      };
    };
  }
  function removeAttribute2(name15) {
    return function(element3) {
      return function() {
        element3.removeAttribute(name15);
      };
    };
  }
  function getBoundingClientRect(el2) {
    return function() {
      var rect = el2.getBoundingClientRect();
      return {
        top: rect.top,
        right: rect.right,
        bottom: rect.bottom,
        left: rect.left,
        width: rect.width,
        height: rect.height,
        x: rect.x,
        y: rect.y
      };
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.Element/index.js
  var map13 = /* @__PURE__ */ map(functorEffect);
  var toParentNode3 = unsafeCoerce2;
  var toNode2 = unsafeCoerce2;
  var getAttribute = function(attr3) {
    var $6 = map13(toMaybe);
    var $7 = _getAttribute(attr3);
    return function($8) {
      return $6($7($8));
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.DOM/index.js
  var $runtime_lazy4 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var haltWidget = function(v) {
    return halt(v.widget);
  };
  var $lazy_patchWidget = /* @__PURE__ */ $runtime_lazy4("patchWidget", "Halogen.VDom.DOM", function() {
    return function(state3, vdom) {
      if (vdom instanceof Grafted) {
        return $lazy_patchWidget(291)(state3, runGraft(vdom.value0));
      }
      ;
      if (vdom instanceof Widget) {
        var res = step2(state3.widget, vdom.value0);
        var res$prime = unStep(function(v) {
          return mkStep(new Step(v.value0, {
            build: state3.build,
            widget: res
          }, $lazy_patchWidget(296), haltWidget));
        })(res);
        return res$prime;
      }
      ;
      haltWidget(state3);
      return state3.build(vdom);
    };
  });
  var patchWidget = /* @__PURE__ */ $lazy_patchWidget(286);
  var haltText = function(v) {
    var parent2 = parentNode(v.node);
    return removeChild(v.node, parent2);
  };
  var $lazy_patchText = /* @__PURE__ */ $runtime_lazy4("patchText", "Halogen.VDom.DOM", function() {
    return function(state3, vdom) {
      if (vdom instanceof Grafted) {
        return $lazy_patchText(82)(state3, runGraft(vdom.value0));
      }
      ;
      if (vdom instanceof Text) {
        if (state3.value === vdom.value0) {
          return mkStep(new Step(state3.node, state3, $lazy_patchText(85), haltText));
        }
        ;
        if (otherwise) {
          var nextState = {
            build: state3.build,
            node: state3.node,
            value: vdom.value0
          };
          setTextContent(vdom.value0, state3.node);
          return mkStep(new Step(state3.node, nextState, $lazy_patchText(89), haltText));
        }
        ;
      }
      ;
      haltText(state3);
      return state3.build(vdom);
    };
  });
  var patchText = /* @__PURE__ */ $lazy_patchText(77);
  var haltKeyed = function(v) {
    var parent2 = parentNode(v.node);
    removeChild(v.node, parent2);
    forInE(v.children, function(v1, s) {
      return halt(s);
    });
    return halt(v.attrs);
  };
  var haltElem = function(v) {
    var parent2 = parentNode(v.node);
    removeChild(v.node, parent2);
    forEachE(v.children, halt);
    return halt(v.attrs);
  };
  var eqElemSpec = function(ns1, v, ns2, v1) {
    var $63 = v === v1;
    if ($63) {
      if (ns1 instanceof Just && (ns2 instanceof Just && ns1.value0 === ns2.value0)) {
        return true;
      }
      ;
      if (ns1 instanceof Nothing && ns2 instanceof Nothing) {
        return true;
      }
      ;
      return false;
    }
    ;
    return false;
  };
  var $lazy_patchElem = /* @__PURE__ */ $runtime_lazy4("patchElem", "Halogen.VDom.DOM", function() {
    return function(state3, vdom) {
      if (vdom instanceof Grafted) {
        return $lazy_patchElem(135)(state3, runGraft(vdom.value0));
      }
      ;
      if (vdom instanceof Elem && eqElemSpec(state3.ns, state3.name, vdom.value0, vdom.value1)) {
        var v = length(vdom.value3);
        var v1 = length(state3.children);
        if (v1 === 0 && v === 0) {
          var attrs2 = step2(state3.attrs, vdom.value2);
          var nextState = {
            build: state3.build,
            node: state3.node,
            attrs: attrs2,
            ns: vdom.value0,
            name: vdom.value1,
            children: state3.children
          };
          return mkStep(new Step(state3.node, nextState, $lazy_patchElem(149), haltElem));
        }
        ;
        var onThis = function(v2, s) {
          return halt(s);
        };
        var onThese = function(ix, s, v2) {
          var res = step2(s, v2);
          insertChildIx(ix, extract2(res), state3.node);
          return res;
        };
        var onThat = function(ix, v2) {
          var res = state3.build(v2);
          insertChildIx(ix, extract2(res), state3.node);
          return res;
        };
        var children2 = diffWithIxE(state3.children, vdom.value3, onThese, onThis, onThat);
        var attrs2 = step2(state3.attrs, vdom.value2);
        var nextState = {
          build: state3.build,
          node: state3.node,
          attrs: attrs2,
          ns: vdom.value0,
          name: vdom.value1,
          children: children2
        };
        return mkStep(new Step(state3.node, nextState, $lazy_patchElem(172), haltElem));
      }
      ;
      haltElem(state3);
      return state3.build(vdom);
    };
  });
  var patchElem = /* @__PURE__ */ $lazy_patchElem(130);
  var $lazy_patchKeyed = /* @__PURE__ */ $runtime_lazy4("patchKeyed", "Halogen.VDom.DOM", function() {
    return function(state3, vdom) {
      if (vdom instanceof Grafted) {
        return $lazy_patchKeyed(222)(state3, runGraft(vdom.value0));
      }
      ;
      if (vdom instanceof Keyed && eqElemSpec(state3.ns, state3.name, vdom.value0, vdom.value1)) {
        var v = length(vdom.value3);
        if (state3.length === 0 && v === 0) {
          var attrs2 = step2(state3.attrs, vdom.value2);
          var nextState = {
            build: state3.build,
            node: state3.node,
            attrs: attrs2,
            ns: vdom.value0,
            name: vdom.value1,
            children: state3.children,
            length: 0
          };
          return mkStep(new Step(state3.node, nextState, $lazy_patchKeyed(237), haltKeyed));
        }
        ;
        var onThis = function(v2, s) {
          return halt(s);
        };
        var onThese = function(v2, ix$prime, s, v3) {
          var res = step2(s, v3.value1);
          insertChildIx(ix$prime, extract2(res), state3.node);
          return res;
        };
        var onThat = function(v2, ix, v3) {
          var res = state3.build(v3.value1);
          insertChildIx(ix, extract2(res), state3.node);
          return res;
        };
        var children2 = diffWithKeyAndIxE(state3.children, vdom.value3, fst, onThese, onThis, onThat);
        var attrs2 = step2(state3.attrs, vdom.value2);
        var nextState = {
          build: state3.build,
          node: state3.node,
          attrs: attrs2,
          ns: vdom.value0,
          name: vdom.value1,
          children: children2,
          length: v
        };
        return mkStep(new Step(state3.node, nextState, $lazy_patchKeyed(261), haltKeyed));
      }
      ;
      haltKeyed(state3);
      return state3.build(vdom);
    };
  });
  var patchKeyed = /* @__PURE__ */ $lazy_patchKeyed(217);
  var buildWidget = function(v, build, w) {
    var res = v.buildWidget(v)(w);
    var res$prime = unStep(function(v1) {
      return mkStep(new Step(v1.value0, {
        build,
        widget: res
      }, patchWidget, haltWidget));
    })(res);
    return res$prime;
  };
  var buildText = function(v, build, s) {
    var node = createTextNode(s, v.document);
    var state3 = {
      build,
      node,
      value: s
    };
    return mkStep(new Step(node, state3, patchText, haltText));
  };
  var buildKeyed = function(v, build, ns1, name1, as1, ch1) {
    var el2 = createElement(toNullable(ns1), name1, v.document);
    var node = toNode2(el2);
    var onChild = function(v1, ix, v2) {
      var res = build(v2.value1);
      insertChildIx(ix, extract2(res), node);
      return res;
    };
    var children2 = strMapWithIxE(ch1, fst, onChild);
    var attrs2 = v.buildAttributes(el2)(as1);
    var state3 = {
      build,
      node,
      attrs: attrs2,
      ns: ns1,
      name: name1,
      children: children2,
      length: length(ch1)
    };
    return mkStep(new Step(node, state3, patchKeyed, haltKeyed));
  };
  var buildElem = function(v, build, ns1, name1, as1, ch1) {
    var el2 = createElement(toNullable(ns1), name1, v.document);
    var node = toNode2(el2);
    var onChild = function(ix, child) {
      var res = build(child);
      insertChildIx(ix, extract2(res), node);
      return res;
    };
    var children2 = forE2(ch1, onChild);
    var attrs2 = v.buildAttributes(el2)(as1);
    var state3 = {
      build,
      node,
      attrs: attrs2,
      ns: ns1,
      name: name1,
      children: children2
    };
    return mkStep(new Step(node, state3, patchElem, haltElem));
  };
  var buildVDom = function(spec) {
    var $lazy_build = $runtime_lazy4("build", "Halogen.VDom.DOM", function() {
      return function(v) {
        if (v instanceof Text) {
          return buildText(spec, $lazy_build(59), v.value0);
        }
        ;
        if (v instanceof Elem) {
          return buildElem(spec, $lazy_build(60), v.value0, v.value1, v.value2, v.value3);
        }
        ;
        if (v instanceof Keyed) {
          return buildKeyed(spec, $lazy_build(61), v.value0, v.value1, v.value2, v.value3);
        }
        ;
        if (v instanceof Widget) {
          return buildWidget(spec, $lazy_build(62), v.value0);
        }
        ;
        if (v instanceof Grafted) {
          return $lazy_build(63)(runGraft(v.value0));
        }
        ;
        throw new Error("Failed pattern match at Halogen.VDom.DOM (line 58, column 27 - line 63, column 52): " + [v.constructor.name]);
      };
    });
    var build = $lazy_build(58);
    return build;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Foreign/foreign.js
  function typeOf(value12) {
    return typeof value12;
  }
  var isArray = Array.isArray || function(value12) {
    return Object.prototype.toString.call(value12) === "[object Array]";
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.List/index.js
  var reverse2 = /* @__PURE__ */ function() {
    var go2 = function($copy_v) {
      return function($copy_v1) {
        var $tco_var_v = $copy_v;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(v, v1) {
          if (v1 instanceof Nil) {
            $tco_done = true;
            return v;
          }
          ;
          if (v1 instanceof Cons) {
            $tco_var_v = new Cons(v1.value0, v);
            $copy_v1 = v1.value1;
            return;
          }
          ;
          throw new Error("Failed pattern match at Data.List (line 368, column 3 - line 368, column 19): " + [v.constructor.name, v1.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_v, $copy_v1);
        }
        ;
        return $tco_result;
      };
    };
    return go2(Nil.value);
  }();
  var $$null2 = function(v) {
    if (v instanceof Nil) {
      return true;
    }
    ;
    return false;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.List.NonEmpty/index.js
  var singleton7 = /* @__PURE__ */ function() {
    var $200 = singleton5(plusList);
    return function($201) {
      return NonEmptyList($200($201));
    };
  }();
  var cons = function(y) {
    return function(v) {
      return new NonEmpty(y, new Cons(v.value0, v.value1));
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Foreign.Object/foreign.js
  function _lookup(no, yes, k, m) {
    return k in m ? yes(m[k]) : no;
  }
  function toArrayWithKey(f) {
    return function(m) {
      var r = [];
      for (var k in m) {
        if (hasOwnProperty.call(m, k)) {
          r.push(f(k)(m[k]));
        }
      }
      return r;
    };
  }
  var keys = Object.keys || toArrayWithKey(function(k) {
    return function() {
      return k;
    };
  });

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Foreign.Object/index.js
  var lookup3 = /* @__PURE__ */ function() {
    return runFn4(_lookup)(Nothing.value)(Just.create);
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.DOM.Prop/index.js
  var $runtime_lazy5 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var Created = /* @__PURE__ */ function() {
    function Created2(value0) {
      this.value0 = value0;
    }
    ;
    Created2.create = function(value0) {
      return new Created2(value0);
    };
    return Created2;
  }();
  var Removed = /* @__PURE__ */ function() {
    function Removed2(value0) {
      this.value0 = value0;
    }
    ;
    Removed2.create = function(value0) {
      return new Removed2(value0);
    };
    return Removed2;
  }();
  var Attribute = /* @__PURE__ */ function() {
    function Attribute2(value0, value1, value22) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value22;
    }
    ;
    Attribute2.create = function(value0) {
      return function(value1) {
        return function(value22) {
          return new Attribute2(value0, value1, value22);
        };
      };
    };
    return Attribute2;
  }();
  var Property = /* @__PURE__ */ function() {
    function Property2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Property2.create = function(value0) {
      return function(value1) {
        return new Property2(value0, value1);
      };
    };
    return Property2;
  }();
  var Handler = /* @__PURE__ */ function() {
    function Handler2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Handler2.create = function(value0) {
      return function(value1) {
        return new Handler2(value0, value1);
      };
    };
    return Handler2;
  }();
  var Ref = /* @__PURE__ */ function() {
    function Ref2(value0) {
      this.value0 = value0;
    }
    ;
    Ref2.create = function(value0) {
      return new Ref2(value0);
    };
    return Ref2;
  }();
  var unsafeGetProperty = unsafeGetAny;
  var setProperty = unsafeSetAny;
  var removeProperty = function(key2, el2) {
    var v = hasAttribute(nullImpl, key2, el2);
    if (v) {
      return removeAttribute(nullImpl, key2, el2);
    }
    ;
    var v1 = typeOf(unsafeGetAny(key2, el2));
    if (v1 === "string") {
      return unsafeSetAny(key2, "", el2);
    }
    ;
    if (key2 === "rowSpan") {
      return unsafeSetAny(key2, 1, el2);
    }
    ;
    if (key2 === "colSpan") {
      return unsafeSetAny(key2, 1, el2);
    }
    ;
    return unsafeSetAny(key2, jsUndefined, el2);
  };
  var propToStrKey = function(v) {
    if (v instanceof Attribute && v.value0 instanceof Just) {
      return "attr/" + (v.value0.value0 + (":" + v.value1));
    }
    ;
    if (v instanceof Attribute) {
      return "attr/:" + v.value1;
    }
    ;
    if (v instanceof Property) {
      return "prop/" + v.value0;
    }
    ;
    if (v instanceof Handler) {
      return "handler/" + v.value0;
    }
    ;
    if (v instanceof Ref) {
      return "ref";
    }
    ;
    throw new Error("Failed pattern match at Halogen.VDom.DOM.Prop (line 182, column 16 - line 187, column 16): " + [v.constructor.name]);
  };
  var propFromString = unsafeCoerce2;
  var propFromInt = unsafeCoerce2;
  var propFromBoolean = unsafeCoerce2;
  var buildProp = function(emit) {
    return function(el2) {
      var removeProp = function(prevEvents) {
        return function(v, v1) {
          if (v1 instanceof Attribute) {
            return removeAttribute(toNullable(v1.value0), v1.value1, el2);
          }
          ;
          if (v1 instanceof Property) {
            return removeProperty(v1.value0, el2);
          }
          ;
          if (v1 instanceof Handler) {
            var handler3 = unsafeLookup(v1.value0, prevEvents);
            return removeEventListener2(v1.value0, fst(handler3), el2);
          }
          ;
          if (v1 instanceof Ref) {
            return unit;
          }
          ;
          throw new Error("Failed pattern match at Halogen.VDom.DOM.Prop (line 169, column 5 - line 179, column 18): " + [v1.constructor.name]);
        };
      };
      var mbEmit = function(v) {
        if (v instanceof Just) {
          return emit(v.value0)();
        }
        ;
        return unit;
      };
      var haltProp = function(state3) {
        var v = lookup3("ref")(state3.props);
        if (v instanceof Just && v.value0 instanceof Ref) {
          return mbEmit(v.value0.value0(new Removed(el2)));
        }
        ;
        return unit;
      };
      var diffProp = function(prevEvents, events) {
        return function(v, v1, v11, v2) {
          if (v11 instanceof Attribute && v2 instanceof Attribute) {
            var $66 = v11.value2 === v2.value2;
            if ($66) {
              return v2;
            }
            ;
            setAttribute(toNullable(v2.value0), v2.value1, v2.value2, el2);
            return v2;
          }
          ;
          if (v11 instanceof Property && v2 instanceof Property) {
            var v4 = refEq2(v11.value1, v2.value1);
            if (v4) {
              return v2;
            }
            ;
            if (v2.value0 === "value") {
              var elVal = unsafeGetProperty("value", el2);
              var $75 = refEq2(elVal, v2.value1);
              if ($75) {
                return v2;
              }
              ;
              setProperty(v2.value0, v2.value1, el2);
              return v2;
            }
            ;
            setProperty(v2.value0, v2.value1, el2);
            return v2;
          }
          ;
          if (v11 instanceof Handler && v2 instanceof Handler) {
            var handler3 = unsafeLookup(v2.value0, prevEvents);
            write(v2.value1)(snd(handler3))();
            pokeMutMap(v2.value0, handler3, events);
            return v2;
          }
          ;
          return v2;
        };
      };
      var applyProp = function(events) {
        return function(v, v1, v2) {
          if (v2 instanceof Attribute) {
            setAttribute(toNullable(v2.value0), v2.value1, v2.value2, el2);
            return v2;
          }
          ;
          if (v2 instanceof Property) {
            setProperty(v2.value0, v2.value1, el2);
            return v2;
          }
          ;
          if (v2 instanceof Handler) {
            var v3 = unsafeGetAny(v2.value0, events);
            if (unsafeHasAny(v2.value0, events)) {
              write(v2.value1)(snd(v3))();
              return v2;
            }
            ;
            var ref3 = $$new(v2.value1)();
            var listener = eventListener(function(ev) {
              return function __do12() {
                var f$prime = read(ref3)();
                return mbEmit(f$prime(ev));
              };
            })();
            pokeMutMap(v2.value0, new Tuple(listener, ref3), events);
            addEventListener2(v2.value0, listener, el2);
            return v2;
          }
          ;
          if (v2 instanceof Ref) {
            mbEmit(v2.value0(new Created(el2)));
            return v2;
          }
          ;
          throw new Error("Failed pattern match at Halogen.VDom.DOM.Prop (line 113, column 5 - line 135, column 15): " + [v2.constructor.name]);
        };
      };
      var $lazy_patchProp = $runtime_lazy5("patchProp", "Halogen.VDom.DOM.Prop", function() {
        return function(state3, ps2) {
          var events = newMutMap();
          var onThis = removeProp(state3.events);
          var onThese = diffProp(state3.events, events);
          var onThat = applyProp(events);
          var props = diffWithKeyAndIxE(state3.props, ps2, propToStrKey, onThese, onThis, onThat);
          var nextState = {
            events: unsafeFreeze2(events),
            props
          };
          return mkStep(new Step(unit, nextState, $lazy_patchProp(100), haltProp));
        };
      });
      var patchProp = $lazy_patchProp(87);
      var renderProp = function(ps1) {
        var events = newMutMap();
        var ps1$prime = strMapWithIxE(ps1, propToStrKey, applyProp(events));
        var state3 = {
          events: unsafeFreeze2(events),
          props: ps1$prime
        };
        return mkStep(new Step(unit, state3, patchProp, haltProp));
      };
      return renderProp;
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.HTML.Core/index.js
  var HTML = function(x) {
    return x;
  };
  var widget = function($28) {
    return HTML(Widget.create($28));
  };
  var toPropValue = function(dict) {
    return dict.toPropValue;
  };
  var text5 = function($29) {
    return HTML(Text.create($29));
  };
  var ref = function(f) {
    return new Ref(function($30) {
      return f(function(v) {
        if (v instanceof Created) {
          return new Just(v.value0);
        }
        ;
        if (v instanceof Removed) {
          return Nothing.value;
        }
        ;
        throw new Error("Failed pattern match at Halogen.HTML.Core (line 109, column 21 - line 111, column 23): " + [v.constructor.name]);
      }($30));
    });
  };
  var prop = function(dictIsProp) {
    var toPropValue1 = toPropValue(dictIsProp);
    return function(v) {
      var $31 = Property.create(v);
      return function($32) {
        return $31(toPropValue1($32));
      };
    };
  };
  var isPropString = {
    toPropValue: propFromString
  };
  var isPropInt = {
    toPropValue: propFromInt
  };
  var isPropButtonType = {
    toPropValue: function($50) {
      return propFromString(renderButtonType($50));
    }
  };
  var isPropBoolean = {
    toPropValue: propFromBoolean
  };
  var handler = /* @__PURE__ */ function() {
    return Handler.create;
  }();
  var element = function(ns) {
    return function(name15) {
      return function(props) {
        return function(children2) {
          return new Elem(ns, name15, props, children2);
        };
      };
    };
  };
  var attr = function(ns) {
    return function(v) {
      return Attribute.create(ns)(v);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Applicative.Free/index.js
  var identity6 = /* @__PURE__ */ identity(categoryFn);
  var Pure = /* @__PURE__ */ function() {
    function Pure2(value0) {
      this.value0 = value0;
    }
    ;
    Pure2.create = function(value0) {
      return new Pure2(value0);
    };
    return Pure2;
  }();
  var Lift = /* @__PURE__ */ function() {
    function Lift3(value0) {
      this.value0 = value0;
    }
    ;
    Lift3.create = function(value0) {
      return new Lift3(value0);
    };
    return Lift3;
  }();
  var Ap = /* @__PURE__ */ function() {
    function Ap2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Ap2.create = function(value0) {
      return function(value1) {
        return new Ap2(value0, value1);
      };
    };
    return Ap2;
  }();
  var mkAp = function(fba) {
    return function(fb) {
      return new Ap(fba, fb);
    };
  };
  var liftFreeAp = /* @__PURE__ */ function() {
    return Lift.create;
  }();
  var goLeft = function(dictApplicative) {
    var pure21 = pure(dictApplicative);
    return function(fStack) {
      return function(valStack) {
        return function(nat) {
          return function(func) {
            return function(count) {
              if (func instanceof Pure) {
                return new Tuple(new Cons({
                  func: pure21(func.value0),
                  count
                }, fStack), valStack);
              }
              ;
              if (func instanceof Lift) {
                return new Tuple(new Cons({
                  func: nat(func.value0),
                  count
                }, fStack), valStack);
              }
              ;
              if (func instanceof Ap) {
                return goLeft(dictApplicative)(fStack)(cons(func.value1)(valStack))(nat)(func.value0)(count + 1 | 0);
              }
              ;
              throw new Error("Failed pattern match at Control.Applicative.Free (line 102, column 41 - line 105, column 81): " + [func.constructor.name]);
            };
          };
        };
      };
    };
  };
  var goApply = function(dictApplicative) {
    var apply2 = apply(dictApplicative.Apply0());
    return function(fStack) {
      return function(vals) {
        return function(gVal) {
          if (fStack instanceof Nil) {
            return new Left(gVal);
          }
          ;
          if (fStack instanceof Cons) {
            var gRes = apply2(fStack.value0.func)(gVal);
            var $31 = fStack.value0.count === 1;
            if ($31) {
              if (fStack.value1 instanceof Nil) {
                return new Left(gRes);
              }
              ;
              return goApply(dictApplicative)(fStack.value1)(vals)(gRes);
            }
            ;
            if (vals instanceof Nil) {
              return new Left(gRes);
            }
            ;
            if (vals instanceof Cons) {
              return new Right(new Tuple(new Cons({
                func: gRes,
                count: fStack.value0.count - 1 | 0
              }, fStack.value1), new NonEmpty(vals.value0, vals.value1)));
            }
            ;
            throw new Error("Failed pattern match at Control.Applicative.Free (line 83, column 11 - line 88, column 50): " + [vals.constructor.name]);
          }
          ;
          throw new Error("Failed pattern match at Control.Applicative.Free (line 72, column 3 - line 88, column 50): " + [fStack.constructor.name]);
        };
      };
    };
  };
  var functorFreeAp = {
    map: function(f) {
      return function(x) {
        return mkAp(new Pure(f))(x);
      };
    }
  };
  var foldFreeAp = function(dictApplicative) {
    var goApply1 = goApply(dictApplicative);
    var pure21 = pure(dictApplicative);
    var goLeft1 = goLeft(dictApplicative);
    return function(nat) {
      return function(z) {
        var go2 = function($copy_v) {
          var $tco_done = false;
          var $tco_result;
          function $tco_loop(v) {
            if (v.value1.value0 instanceof Pure) {
              var v1 = goApply1(v.value0)(v.value1.value1)(pure21(v.value1.value0.value0));
              if (v1 instanceof Left) {
                $tco_done = true;
                return v1.value0;
              }
              ;
              if (v1 instanceof Right) {
                $copy_v = v1.value0;
                return;
              }
              ;
              throw new Error("Failed pattern match at Control.Applicative.Free (line 54, column 17 - line 56, column 24): " + [v1.constructor.name]);
            }
            ;
            if (v.value1.value0 instanceof Lift) {
              var v1 = goApply1(v.value0)(v.value1.value1)(nat(v.value1.value0.value0));
              if (v1 instanceof Left) {
                $tco_done = true;
                return v1.value0;
              }
              ;
              if (v1 instanceof Right) {
                $copy_v = v1.value0;
                return;
              }
              ;
              throw new Error("Failed pattern match at Control.Applicative.Free (line 57, column 17 - line 59, column 24): " + [v1.constructor.name]);
            }
            ;
            if (v.value1.value0 instanceof Ap) {
              var nextVals = new NonEmpty(v.value1.value0.value1, v.value1.value1);
              $copy_v = goLeft1(v.value0)(nextVals)(nat)(v.value1.value0.value0)(1);
              return;
            }
            ;
            throw new Error("Failed pattern match at Control.Applicative.Free (line 53, column 5 - line 62, column 47): " + [v.value1.value0.constructor.name]);
          }
          ;
          while (!$tco_done) {
            $tco_result = $tco_loop($copy_v);
          }
          ;
          return $tco_result;
        };
        return go2(new Tuple(Nil.value, singleton7(z)));
      };
    };
  };
  var retractFreeAp = function(dictApplicative) {
    return foldFreeAp(dictApplicative)(identity6);
  };
  var applyFreeAp = {
    apply: function(fba) {
      return function(fb) {
        return mkAp(fba)(fb);
      };
    },
    Functor0: function() {
      return functorFreeAp;
    }
  };
  var applicativeFreeAp = /* @__PURE__ */ function() {
    return {
      pure: Pure.create,
      Apply0: function() {
        return applyFreeAp;
      }
    };
  }();
  var foldFreeAp1 = /* @__PURE__ */ foldFreeAp(applicativeFreeAp);
  var hoistFreeAp = function(f) {
    return foldFreeAp1(function($54) {
      return liftFreeAp(f($54));
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.CatQueue/index.js
  var CatQueue = /* @__PURE__ */ function() {
    function CatQueue2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    CatQueue2.create = function(value0) {
      return function(value1) {
        return new CatQueue2(value0, value1);
      };
    };
    return CatQueue2;
  }();
  var uncons3 = function($copy_v) {
    var $tco_done = false;
    var $tco_result;
    function $tco_loop(v) {
      if (v.value0 instanceof Nil && v.value1 instanceof Nil) {
        $tco_done = true;
        return Nothing.value;
      }
      ;
      if (v.value0 instanceof Nil) {
        $copy_v = new CatQueue(reverse2(v.value1), Nil.value);
        return;
      }
      ;
      if (v.value0 instanceof Cons) {
        $tco_done = true;
        return new Just(new Tuple(v.value0.value0, new CatQueue(v.value0.value1, v.value1)));
      }
      ;
      throw new Error("Failed pattern match at Data.CatQueue (line 82, column 1 - line 82, column 63): " + [v.constructor.name]);
    }
    ;
    while (!$tco_done) {
      $tco_result = $tco_loop($copy_v);
    }
    ;
    return $tco_result;
  };
  var snoc2 = function(v) {
    return function(a2) {
      return new CatQueue(v.value0, new Cons(a2, v.value1));
    };
  };
  var $$null3 = function(v) {
    if (v.value0 instanceof Nil && v.value1 instanceof Nil) {
      return true;
    }
    ;
    return false;
  };
  var empty5 = /* @__PURE__ */ function() {
    return new CatQueue(Nil.value, Nil.value);
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Data.CatList/index.js
  var CatNil = /* @__PURE__ */ function() {
    function CatNil2() {
    }
    ;
    CatNil2.value = new CatNil2();
    return CatNil2;
  }();
  var CatCons = /* @__PURE__ */ function() {
    function CatCons2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    CatCons2.create = function(value0) {
      return function(value1) {
        return new CatCons2(value0, value1);
      };
    };
    return CatCons2;
  }();
  var link = function(v) {
    return function(v1) {
      if (v instanceof CatNil) {
        return v1;
      }
      ;
      if (v1 instanceof CatNil) {
        return v;
      }
      ;
      if (v instanceof CatCons) {
        return new CatCons(v.value0, snoc2(v.value1)(v1));
      }
      ;
      throw new Error("Failed pattern match at Data.CatList (line 108, column 1 - line 108, column 54): " + [v.constructor.name, v1.constructor.name]);
    };
  };
  var foldr3 = function(k) {
    return function(b2) {
      return function(q2) {
        var foldl5 = function($copy_v) {
          return function($copy_v1) {
            return function($copy_v2) {
              var $tco_var_v = $copy_v;
              var $tco_var_v1 = $copy_v1;
              var $tco_done = false;
              var $tco_result;
              function $tco_loop(v, v1, v2) {
                if (v2 instanceof Nil) {
                  $tco_done = true;
                  return v1;
                }
                ;
                if (v2 instanceof Cons) {
                  $tco_var_v = v;
                  $tco_var_v1 = v(v1)(v2.value0);
                  $copy_v2 = v2.value1;
                  return;
                }
                ;
                throw new Error("Failed pattern match at Data.CatList (line 124, column 3 - line 124, column 59): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
              }
              ;
              while (!$tco_done) {
                $tco_result = $tco_loop($tco_var_v, $tco_var_v1, $copy_v2);
              }
              ;
              return $tco_result;
            };
          };
        };
        var go2 = function($copy_xs) {
          return function($copy_ys) {
            var $tco_var_xs = $copy_xs;
            var $tco_done1 = false;
            var $tco_result;
            function $tco_loop(xs, ys) {
              var v = uncons3(xs);
              if (v instanceof Nothing) {
                $tco_done1 = true;
                return foldl5(function(x) {
                  return function(i2) {
                    return i2(x);
                  };
                })(b2)(ys);
              }
              ;
              if (v instanceof Just) {
                $tco_var_xs = v.value0.value1;
                $copy_ys = new Cons(k(v.value0.value0), ys);
                return;
              }
              ;
              throw new Error("Failed pattern match at Data.CatList (line 120, column 14 - line 122, column 67): " + [v.constructor.name]);
            }
            ;
            while (!$tco_done1) {
              $tco_result = $tco_loop($tco_var_xs, $copy_ys);
            }
            ;
            return $tco_result;
          };
        };
        return go2(q2)(Nil.value);
      };
    };
  };
  var uncons4 = function(v) {
    if (v instanceof CatNil) {
      return Nothing.value;
    }
    ;
    if (v instanceof CatCons) {
      return new Just(new Tuple(v.value0, function() {
        var $66 = $$null3(v.value1);
        if ($66) {
          return CatNil.value;
        }
        ;
        return foldr3(link)(CatNil.value)(v.value1);
      }()));
    }
    ;
    throw new Error("Failed pattern match at Data.CatList (line 99, column 1 - line 99, column 61): " + [v.constructor.name]);
  };
  var empty6 = /* @__PURE__ */ function() {
    return CatNil.value;
  }();
  var append2 = link;
  var semigroupCatList = {
    append: append2
  };
  var snoc3 = function(cat) {
    return function(a2) {
      return append2(cat)(new CatCons(a2, empty5));
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Monad.Free/index.js
  var $runtime_lazy6 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var append3 = /* @__PURE__ */ append(semigroupCatList);
  var Free = /* @__PURE__ */ function() {
    function Free2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Free2.create = function(value0) {
      return function(value1) {
        return new Free2(value0, value1);
      };
    };
    return Free2;
  }();
  var Return = /* @__PURE__ */ function() {
    function Return2(value0) {
      this.value0 = value0;
    }
    ;
    Return2.create = function(value0) {
      return new Return2(value0);
    };
    return Return2;
  }();
  var Bind = /* @__PURE__ */ function() {
    function Bind2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Bind2.create = function(value0) {
      return function(value1) {
        return new Bind2(value0, value1);
      };
    };
    return Bind2;
  }();
  var toView = function($copy_v) {
    var $tco_done = false;
    var $tco_result;
    function $tco_loop(v) {
      var runExpF = function(v22) {
        return v22;
      };
      var concatF = function(v22) {
        return function(r) {
          return new Free(v22.value0, append3(v22.value1)(r));
        };
      };
      if (v.value0 instanceof Return) {
        var v2 = uncons4(v.value1);
        if (v2 instanceof Nothing) {
          $tco_done = true;
          return new Return(v.value0.value0);
        }
        ;
        if (v2 instanceof Just) {
          $copy_v = concatF(runExpF(v2.value0.value0)(v.value0.value0))(v2.value0.value1);
          return;
        }
        ;
        throw new Error("Failed pattern match at Control.Monad.Free (line 227, column 7 - line 231, column 64): " + [v2.constructor.name]);
      }
      ;
      if (v.value0 instanceof Bind) {
        $tco_done = true;
        return new Bind(v.value0.value0, function(a2) {
          return concatF(v.value0.value1(a2))(v.value1);
        });
      }
      ;
      throw new Error("Failed pattern match at Control.Monad.Free (line 225, column 3 - line 233, column 56): " + [v.value0.constructor.name]);
    }
    ;
    while (!$tco_done) {
      $tco_result = $tco_loop($copy_v);
    }
    ;
    return $tco_result;
  };
  var fromView = function(f) {
    return new Free(f, empty6);
  };
  var freeMonad = {
    Applicative0: function() {
      return freeApplicative;
    },
    Bind1: function() {
      return freeBind;
    }
  };
  var freeFunctor = {
    map: function(k) {
      return function(f) {
        return bindFlipped(freeBind)(function() {
          var $189 = pure(freeApplicative);
          return function($190) {
            return $189(k($190));
          };
        }())(f);
      };
    }
  };
  var freeBind = {
    bind: function(v) {
      return function(k) {
        return new Free(v.value0, snoc3(v.value1)(k));
      };
    },
    Apply0: function() {
      return $lazy_freeApply(0);
    }
  };
  var freeApplicative = {
    pure: function($191) {
      return fromView(Return.create($191));
    },
    Apply0: function() {
      return $lazy_freeApply(0);
    }
  };
  var $lazy_freeApply = /* @__PURE__ */ $runtime_lazy6("freeApply", "Control.Monad.Free", function() {
    return {
      apply: ap(freeMonad),
      Functor0: function() {
        return freeFunctor;
      }
    };
  });
  var pure4 = /* @__PURE__ */ pure(freeApplicative);
  var liftF = function(f) {
    return fromView(new Bind(f, function($192) {
      return pure4($192);
    }));
  };
  var foldFree = function(dictMonadRec) {
    var Monad0 = dictMonadRec.Monad0();
    var map117 = map(Monad0.Bind1().Apply0().Functor0());
    var pure110 = pure(Monad0.Applicative0());
    var tailRecM4 = tailRecM(dictMonadRec);
    return function(k) {
      var go2 = function(f) {
        var v = toView(f);
        if (v instanceof Return) {
          return map117(Done.create)(pure110(v.value0));
        }
        ;
        if (v instanceof Bind) {
          return map117(function($199) {
            return Loop.create(v.value1($199));
          })(k(v.value0));
        }
        ;
        throw new Error("Failed pattern match at Control.Monad.Free (line 158, column 10 - line 160, column 37): " + [v.constructor.name]);
      };
      return tailRecM4(go2);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Query.ChildQuery/index.js
  var unChildQueryBox = unsafeCoerce2;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Unsafe.Reference/foreign.js
  function reallyUnsafeRefEq(a2) {
    return function(b2) {
      return a2 === b2;
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Unsafe.Reference/index.js
  var unsafeRefEq = reallyUnsafeRefEq;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Subscription/index.js
  var $$void4 = /* @__PURE__ */ $$void(functorEffect);
  var coerce3 = /* @__PURE__ */ coerce();
  var bind3 = /* @__PURE__ */ bind(bindEffect);
  var append4 = /* @__PURE__ */ append(semigroupArray);
  var traverse_2 = /* @__PURE__ */ traverse_(applicativeEffect);
  var traverse_1 = /* @__PURE__ */ traverse_2(foldableArray);
  var unsubscribe = function(v) {
    return v;
  };
  var subscribe = function(v) {
    return function(k) {
      return v(function($76) {
        return $$void4(k($76));
      });
    };
  };
  var notify = function(v) {
    return function(a2) {
      return v(a2);
    };
  };
  var makeEmitter = coerce3;
  var functorEmitter = {
    map: function(f) {
      return function(v) {
        return function(k) {
          return v(function($77) {
            return k(f($77));
          });
        };
      };
    }
  };
  var create3 = function __do() {
    var subscribers = $$new([])();
    return {
      emitter: function(k) {
        return function __do12() {
          modify_(function(v) {
            return append4(v)([k]);
          })(subscribers)();
          return modify_(deleteBy(unsafeRefEq)(k))(subscribers);
        };
      },
      listener: function(a2) {
        return bind3(read(subscribers))(traverse_1(function(k) {
          return k(a2);
        }));
      }
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Query.HalogenM/index.js
  var identity7 = /* @__PURE__ */ identity(categoryFn);
  var SubscriptionId = function(x) {
    return x;
  };
  var ForkId = function(x) {
    return x;
  };
  var State = /* @__PURE__ */ function() {
    function State2(value0) {
      this.value0 = value0;
    }
    ;
    State2.create = function(value0) {
      return new State2(value0);
    };
    return State2;
  }();
  var Subscribe = /* @__PURE__ */ function() {
    function Subscribe2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Subscribe2.create = function(value0) {
      return function(value1) {
        return new Subscribe2(value0, value1);
      };
    };
    return Subscribe2;
  }();
  var Unsubscribe = /* @__PURE__ */ function() {
    function Unsubscribe2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Unsubscribe2.create = function(value0) {
      return function(value1) {
        return new Unsubscribe2(value0, value1);
      };
    };
    return Unsubscribe2;
  }();
  var Lift2 = /* @__PURE__ */ function() {
    function Lift3(value0) {
      this.value0 = value0;
    }
    ;
    Lift3.create = function(value0) {
      return new Lift3(value0);
    };
    return Lift3;
  }();
  var ChildQuery2 = /* @__PURE__ */ function() {
    function ChildQuery3(value0) {
      this.value0 = value0;
    }
    ;
    ChildQuery3.create = function(value0) {
      return new ChildQuery3(value0);
    };
    return ChildQuery3;
  }();
  var Raise = /* @__PURE__ */ function() {
    function Raise2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Raise2.create = function(value0) {
      return function(value1) {
        return new Raise2(value0, value1);
      };
    };
    return Raise2;
  }();
  var Par = /* @__PURE__ */ function() {
    function Par2(value0) {
      this.value0 = value0;
    }
    ;
    Par2.create = function(value0) {
      return new Par2(value0);
    };
    return Par2;
  }();
  var Fork = /* @__PURE__ */ function() {
    function Fork2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Fork2.create = function(value0) {
      return function(value1) {
        return new Fork2(value0, value1);
      };
    };
    return Fork2;
  }();
  var Join = /* @__PURE__ */ function() {
    function Join2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Join2.create = function(value0) {
      return function(value1) {
        return new Join2(value0, value1);
      };
    };
    return Join2;
  }();
  var Kill = /* @__PURE__ */ function() {
    function Kill2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Kill2.create = function(value0) {
      return function(value1) {
        return new Kill2(value0, value1);
      };
    };
    return Kill2;
  }();
  var GetRef = /* @__PURE__ */ function() {
    function GetRef2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    GetRef2.create = function(value0) {
      return function(value1) {
        return new GetRef2(value0, value1);
      };
    };
    return GetRef2;
  }();
  var HalogenM = function(x) {
    return x;
  };
  var unsubscribe2 = function(sid) {
    return liftF(new Unsubscribe(sid, unit));
  };
  var subscribe2 = function(es) {
    return liftF(new Subscribe(function(v) {
      return es;
    }, identity7));
  };
  var raise = function(o) {
    return liftF(new Raise(o, unit));
  };
  var ordSubscriptionId = ordInt;
  var ordForkId = ordInt;
  var monadHalogenM = freeMonad;
  var monadStateHalogenM = {
    state: function($181) {
      return HalogenM(liftF(State.create($181)));
    },
    Monad0: function() {
      return monadHalogenM;
    }
  };
  var monadEffectHalogenM = function(dictMonadEffect) {
    return {
      liftEffect: function() {
        var $186 = liftEffect(dictMonadEffect);
        return function($187) {
          return HalogenM(liftF(Lift2.create($186($187))));
        };
      }(),
      Monad0: function() {
        return monadHalogenM;
      }
    };
  };
  var getRef = function(p2) {
    return liftF(new GetRef(p2, identity7));
  };
  var functorHalogenM = freeFunctor;
  var bindHalogenM = freeBind;
  var applicativeHalogenM = freeApplicative;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Query.HalogenQ/index.js
  var Initialize = /* @__PURE__ */ function() {
    function Initialize9(value0) {
      this.value0 = value0;
    }
    ;
    Initialize9.create = function(value0) {
      return new Initialize9(value0);
    };
    return Initialize9;
  }();
  var Finalize = /* @__PURE__ */ function() {
    function Finalize2(value0) {
      this.value0 = value0;
    }
    ;
    Finalize2.create = function(value0) {
      return new Finalize2(value0);
    };
    return Finalize2;
  }();
  var Receive = /* @__PURE__ */ function() {
    function Receive10(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Receive10.create = function(value0) {
      return function(value1) {
        return new Receive10(value0, value1);
      };
    };
    return Receive10;
  }();
  var Action2 = /* @__PURE__ */ function() {
    function Action3(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Action3.create = function(value0) {
      return function(value1) {
        return new Action3(value0, value1);
      };
    };
    return Action3;
  }();
  var Query = /* @__PURE__ */ function() {
    function Query2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Query2.create = function(value0) {
      return function(value1) {
        return new Query2(value0, value1);
      };
    };
    return Query2;
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.Thunk/index.js
  var $runtime_lazy7 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var unsafeEqThunk = function(v, v1) {
    return refEq2(v.value0, v1.value0) && (refEq2(v.value1, v1.value1) && v.value1(v.value3, v1.value3));
  };
  var runThunk = function(v) {
    return v.value2(v.value3);
  };
  var buildThunk = function(toVDom) {
    var haltThunk = function(state3) {
      return halt(state3.vdom);
    };
    var $lazy_patchThunk = $runtime_lazy7("patchThunk", "Halogen.VDom.Thunk", function() {
      return function(state3, t2) {
        var $48 = unsafeEqThunk(state3.thunk, t2);
        if ($48) {
          return mkStep(new Step(extract2(state3.vdom), state3, $lazy_patchThunk(112), haltThunk));
        }
        ;
        var vdom = step2(state3.vdom, toVDom(runThunk(t2)));
        return mkStep(new Step(extract2(vdom), {
          vdom,
          thunk: t2
        }, $lazy_patchThunk(115), haltThunk));
      };
    });
    var patchThunk = $lazy_patchThunk(108);
    var renderThunk = function(spec) {
      return function(t) {
        var vdom = buildVDom(spec)(toVDom(runThunk(t)));
        return mkStep(new Step(extract2(vdom), {
          thunk: t,
          vdom
        }, patchThunk, haltThunk));
      };
    };
    return renderThunk;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Component/index.js
  var voidLeft2 = /* @__PURE__ */ voidLeft(functorHalogenM);
  var traverse_3 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableMaybe);
  var map14 = /* @__PURE__ */ map(functorHalogenM);
  var pure5 = /* @__PURE__ */ pure(applicativeHalogenM);
  var lookup4 = /* @__PURE__ */ lookup2();
  var pop3 = /* @__PURE__ */ pop2();
  var insert3 = /* @__PURE__ */ insert2();
  var ComponentSlot = /* @__PURE__ */ function() {
    function ComponentSlot2(value0) {
      this.value0 = value0;
    }
    ;
    ComponentSlot2.create = function(value0) {
      return new ComponentSlot2(value0);
    };
    return ComponentSlot2;
  }();
  var ThunkSlot = /* @__PURE__ */ function() {
    function ThunkSlot2(value0) {
      this.value0 = value0;
    }
    ;
    ThunkSlot2.create = function(value0) {
      return new ThunkSlot2(value0);
    };
    return ThunkSlot2;
  }();
  var unComponentSlot = unsafeCoerce2;
  var unComponent = unsafeCoerce2;
  var mkEval = function(args) {
    return function(v) {
      if (v instanceof Initialize) {
        return voidLeft2(traverse_3(args.handleAction)(args.initialize))(v.value0);
      }
      ;
      if (v instanceof Finalize) {
        return voidLeft2(traverse_3(args.handleAction)(args.finalize))(v.value0);
      }
      ;
      if (v instanceof Receive) {
        return voidLeft2(traverse_3(args.handleAction)(args.receive(v.value0)))(v.value1);
      }
      ;
      if (v instanceof Action2) {
        return voidLeft2(args.handleAction(v.value0))(v.value1);
      }
      ;
      if (v instanceof Query) {
        return unCoyoneda(function(g) {
          var $45 = map14(maybe(v.value1(unit))(g));
          return function($46) {
            return $45(args.handleQuery($46));
          };
        })(v.value0);
      }
      ;
      throw new Error("Failed pattern match at Halogen.Component (line 182, column 15 - line 192, column 71): " + [v.constructor.name]);
    };
  };
  var mkComponentSlot = unsafeCoerce2;
  var mkComponent = unsafeCoerce2;
  var defaultEval = /* @__PURE__ */ function() {
    return {
      handleAction: $$const(pure5(unit)),
      handleQuery: $$const(pure5(Nothing.value)),
      receive: $$const(Nothing.value),
      initialize: Nothing.value,
      finalize: Nothing.value
    };
  }();
  var componentSlot = function() {
    return function(dictIsSymbol) {
      var lookup13 = lookup4(dictIsSymbol);
      var pop12 = pop3(dictIsSymbol);
      var insert13 = insert3(dictIsSymbol);
      return function(dictOrd) {
        var lookup23 = lookup13(dictOrd);
        var pop22 = pop12(dictOrd);
        var insert22 = insert13(dictOrd);
        return function(label5) {
          return function(p2) {
            return function(comp) {
              return function(input3) {
                return function(output2) {
                  return mkComponentSlot({
                    get: lookup23(label5)(p2),
                    pop: pop22(label5)(p2),
                    set: insert22(label5)(p2),
                    component: comp,
                    input: input3,
                    output: output2
                  });
                };
              };
            };
          };
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.HTML.Elements/index.js
  var pure6 = /* @__PURE__ */ pure(applicativeMaybe);
  var elementNS = function($15) {
    return element(pure6($15));
  };
  var element2 = /* @__PURE__ */ function() {
    return element(Nothing.value);
  }();
  var h1 = /* @__PURE__ */ element2("h1");
  var input = function(props) {
    return element2("input")(props)([]);
  };
  var label4 = /* @__PURE__ */ element2("label");
  var label_ = /* @__PURE__ */ label4([]);
  var p = /* @__PURE__ */ element2("p");
  var span3 = /* @__PURE__ */ element2("span");
  var textarea = function(es) {
    return element2("textarea")(es)([]);
  };
  var div3 = /* @__PURE__ */ element2("div");
  var div_ = /* @__PURE__ */ div3([]);
  var button = /* @__PURE__ */ element2("button");
  var a = /* @__PURE__ */ element2("a");

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.HTML.Properties/index.js
  var unwrap2 = /* @__PURE__ */ unwrap();
  var ref2 = /* @__PURE__ */ function() {
    var go2 = function(p2) {
      return function(mel) {
        return new Just(new RefUpdate(p2, mel));
      };
    };
    return function($29) {
      return ref(go2($29));
    };
  }();
  var prop2 = function(dictIsProp) {
    return prop(dictIsProp);
  };
  var prop1 = /* @__PURE__ */ prop2(isPropBoolean);
  var prop22 = /* @__PURE__ */ prop2(isPropString);
  var prop3 = /* @__PURE__ */ prop2(isPropInt);
  var spellcheck2 = /* @__PURE__ */ prop1("spellcheck");
  var tabIndex2 = /* @__PURE__ */ prop3("tabIndex");
  var type_17 = function(dictIsProp) {
    return prop2(dictIsProp)("type");
  };
  var placeholder3 = /* @__PURE__ */ prop22("placeholder");
  var id2 = /* @__PURE__ */ prop22("id");
  var href4 = /* @__PURE__ */ prop22("href");
  var classes = /* @__PURE__ */ function() {
    var $32 = prop22("className");
    var $33 = joinWith(" ");
    var $34 = map(functorArray)(unwrap2);
    return function($35) {
      return $32($33($34($35)));
    };
  }();
  var class_ = /* @__PURE__ */ function() {
    var $36 = prop22("className");
    return function($37) {
      return $36(unwrap2($37));
    };
  }();
  var attr2 = /* @__PURE__ */ function() {
    return attr(Nothing.value);
  }();
  var style = /* @__PURE__ */ attr2("style");

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.HTML/index.js
  var componentSlot2 = /* @__PURE__ */ componentSlot();
  var slot_ = function() {
    return function(dictIsSymbol) {
      var componentSlot1 = componentSlot2(dictIsSymbol);
      return function(dictOrd) {
        var componentSlot22 = componentSlot1(dictOrd);
        return function(label5) {
          return function(p2) {
            return function(component10) {
              return function(input3) {
                return widget(new ComponentSlot(componentSlot22(label5)(p2)(component10)(input3)($$const(Nothing.value))));
              };
            };
          };
        };
      };
    };
  };
  var fromPlainHTML = unsafeCoerce2;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Control.Monad.Fork.Class/index.js
  var monadForkAff = {
    suspend: suspendAff,
    fork: forkAff,
    join: joinFiber,
    Monad0: function() {
      return monadAff;
    },
    Functor1: function() {
      return functorFiber;
    }
  };
  var fork = function(dict) {
    return dict.fork;
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Effect.Console/foreign.js
  var warn = function(s) {
    return function() {
      console.warn(s);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Query/index.js
  var bindFlipped5 = /* @__PURE__ */ bindFlipped(bindMaybe);
  var getHTMLElementRef = /* @__PURE__ */ function() {
    var $24 = map(functorHalogenM)(function(v) {
      return bindFlipped5(fromElement)(v);
    });
    return function($25) {
      return $24(getRef($25));
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Aff.Driver.State/index.js
  var unRenderStateX = unsafeCoerce2;
  var unDriverStateX = unsafeCoerce2;
  var renderStateX_ = function(dictApplicative) {
    var traverse_17 = traverse_(dictApplicative)(foldableMaybe);
    return function(f) {
      return unDriverStateX(function(st) {
        return traverse_17(f)(st.rendering);
      });
    };
  };
  var mkRenderStateX = unsafeCoerce2;
  var renderStateX = function(dictFunctor) {
    return function(f) {
      return unDriverStateX(function(st) {
        return mkRenderStateX(f(st.rendering));
      });
    };
  };
  var mkDriverStateXRef = unsafeCoerce2;
  var mapDriverState = function(f) {
    return function(v) {
      return f(v);
    };
  };
  var initDriverState = function(component10) {
    return function(input3) {
      return function(handler3) {
        return function(lchs) {
          return function __do12() {
            var selfRef = $$new({})();
            var childrenIn = $$new(empty3)();
            var childrenOut = $$new(empty3)();
            var handlerRef = $$new(handler3)();
            var pendingQueries = $$new(new Just(Nil.value))();
            var pendingOuts = $$new(new Just(Nil.value))();
            var pendingHandlers = $$new(Nothing.value)();
            var fresh2 = $$new(1)();
            var subscriptions = $$new(new Just(empty2))();
            var forks = $$new(empty2)();
            var ds = {
              component: component10,
              state: component10.initialState(input3),
              refs: empty2,
              children: empty3,
              childrenIn,
              childrenOut,
              selfRef,
              handlerRef,
              pendingQueries,
              pendingOuts,
              pendingHandlers,
              rendering: Nothing.value,
              fresh: fresh2,
              subscriptions,
              forks,
              lifecycleHandlers: lchs
            };
            write(ds)(selfRef)();
            return mkDriverStateXRef(selfRef);
          };
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Aff.Driver.Eval/index.js
  var traverse_4 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableMaybe);
  var bindFlipped6 = /* @__PURE__ */ bindFlipped(bindMaybe);
  var lookup5 = /* @__PURE__ */ lookup(ordSubscriptionId);
  var bind12 = /* @__PURE__ */ bind(bindAff);
  var liftEffect4 = /* @__PURE__ */ liftEffect(monadEffectAff);
  var discard2 = /* @__PURE__ */ discard(discardUnit);
  var discard1 = /* @__PURE__ */ discard2(bindAff);
  var traverse_12 = /* @__PURE__ */ traverse_(applicativeAff);
  var traverse_22 = /* @__PURE__ */ traverse_12(foldableList);
  var fork3 = /* @__PURE__ */ fork(monadForkAff);
  var parSequence_2 = /* @__PURE__ */ parSequence_(parallelAff)(applicativeParAff)(foldableList);
  var pure7 = /* @__PURE__ */ pure(applicativeAff);
  var map16 = /* @__PURE__ */ map(functorCoyoneda);
  var parallel3 = /* @__PURE__ */ parallel(parallelAff);
  var map17 = /* @__PURE__ */ map(functorAff);
  var sequential2 = /* @__PURE__ */ sequential(parallelAff);
  var map22 = /* @__PURE__ */ map(functorMaybe);
  var insert4 = /* @__PURE__ */ insert(ordSubscriptionId);
  var retractFreeAp2 = /* @__PURE__ */ retractFreeAp(applicativeParAff);
  var $$delete2 = /* @__PURE__ */ $$delete(ordForkId);
  var unlessM2 = /* @__PURE__ */ unlessM(monadEffect);
  var insert12 = /* @__PURE__ */ insert(ordForkId);
  var traverse_32 = /* @__PURE__ */ traverse_12(foldableMaybe);
  var lookup12 = /* @__PURE__ */ lookup(ordForkId);
  var lookup22 = /* @__PURE__ */ lookup(ordString);
  var foldFree2 = /* @__PURE__ */ foldFree(monadRecAff);
  var alter2 = /* @__PURE__ */ alter(ordString);
  var unsubscribe3 = function(sid) {
    return function(ref3) {
      return function __do12() {
        var v = read(ref3)();
        var subs = read(v.subscriptions)();
        return traverse_4(unsubscribe)(bindFlipped6(lookup5(sid))(subs))();
      };
    };
  };
  var queueOrRun = function(ref3) {
    return function(au) {
      return bind12(liftEffect4(read(ref3)))(function(v) {
        if (v instanceof Nothing) {
          return au;
        }
        ;
        if (v instanceof Just) {
          return liftEffect4(write(new Just(new Cons(au, v.value0)))(ref3));
        }
        ;
        throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 188, column 33 - line 190, column 57): " + [v.constructor.name]);
      });
    };
  };
  var handleLifecycle = function(lchs) {
    return function(f) {
      return discard1(liftEffect4(write({
        initializers: Nil.value,
        finalizers: Nil.value
      })(lchs)))(function() {
        return bind12(liftEffect4(f))(function(result) {
          return bind12(liftEffect4(read(lchs)))(function(v) {
            return discard1(traverse_22(fork3)(v.finalizers))(function() {
              return discard1(parSequence_2(v.initializers))(function() {
                return pure7(result);
              });
            });
          });
        });
      });
    };
  };
  var handleAff = /* @__PURE__ */ runAff_(/* @__PURE__ */ either(throwException)(/* @__PURE__ */ $$const(/* @__PURE__ */ pure(applicativeEffect)(unit))));
  var fresh = function(f) {
    return function(ref3) {
      return bind12(liftEffect4(read(ref3)))(function(v) {
        return liftEffect4(modify$prime(function(i2) {
          return {
            state: i2 + 1 | 0,
            value: f(i2)
          };
        })(v.fresh));
      });
    };
  };
  var evalQ = function(render9) {
    return function(ref3) {
      return function(q2) {
        return bind12(liftEffect4(read(ref3)))(function(v) {
          return evalM(render9)(ref3)(v["component"]["eval"](new Query(map16(Just.create)(liftCoyoneda(q2)), $$const(Nothing.value))));
        });
      };
    };
  };
  var evalM = function(render9) {
    return function(initRef) {
      return function(v) {
        var evalChildQuery = function(ref3) {
          return function(cqb) {
            return bind12(liftEffect4(read(ref3)))(function(v1) {
              return unChildQueryBox(function(v2) {
                var evalChild = function(v3) {
                  return parallel3(bind12(liftEffect4(read(v3)))(function(dsx) {
                    return unDriverStateX(function(ds) {
                      return evalQ(render9)(ds.selfRef)(v2.value1);
                    })(dsx);
                  }));
                };
                return map17(v2.value2)(sequential2(v2.value0(applicativeParAff)(evalChild)(v1.children)));
              })(cqb);
            });
          };
        };
        var go2 = function(ref3) {
          return function(v1) {
            if (v1 instanceof State) {
              return bind12(liftEffect4(read(ref3)))(function(v2) {
                var v3 = v1.value0(v2.state);
                if (unsafeRefEq(v2.state)(v3.value1)) {
                  return pure7(v3.value0);
                }
                ;
                if (otherwise) {
                  return discard1(liftEffect4(write({
                    component: v2.component,
                    refs: v2.refs,
                    children: v2.children,
                    childrenIn: v2.childrenIn,
                    childrenOut: v2.childrenOut,
                    selfRef: v2.selfRef,
                    handlerRef: v2.handlerRef,
                    pendingQueries: v2.pendingQueries,
                    pendingOuts: v2.pendingOuts,
                    pendingHandlers: v2.pendingHandlers,
                    rendering: v2.rendering,
                    fresh: v2.fresh,
                    subscriptions: v2.subscriptions,
                    forks: v2.forks,
                    lifecycleHandlers: v2.lifecycleHandlers,
                    state: v3.value1
                  })(ref3)))(function() {
                    return discard1(handleLifecycle(v2.lifecycleHandlers)(render9(v2.lifecycleHandlers)(ref3)))(function() {
                      return pure7(v3.value0);
                    });
                  });
                }
                ;
                throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 86, column 7 - line 92, column 21): " + [v3.constructor.name]);
              });
            }
            ;
            if (v1 instanceof Subscribe) {
              return bind12(fresh(SubscriptionId)(ref3))(function(sid) {
                return bind12(liftEffect4(subscribe(v1.value0(sid))(function(act) {
                  return handleAff(evalF(render9)(ref3)(new Action(act)));
                })))(function(finalize7) {
                  return bind12(liftEffect4(read(ref3)))(function(v2) {
                    return discard1(liftEffect4(modify_(map22(insert4(sid)(finalize7)))(v2.subscriptions)))(function() {
                      return pure7(v1.value1(sid));
                    });
                  });
                });
              });
            }
            ;
            if (v1 instanceof Unsubscribe) {
              return discard1(liftEffect4(unsubscribe3(v1.value0)(ref3)))(function() {
                return pure7(v1.value1);
              });
            }
            ;
            if (v1 instanceof Lift2) {
              return v1.value0;
            }
            ;
            if (v1 instanceof ChildQuery2) {
              return evalChildQuery(ref3)(v1.value0);
            }
            ;
            if (v1 instanceof Raise) {
              return bind12(liftEffect4(read(ref3)))(function(v2) {
                return bind12(liftEffect4(read(v2.handlerRef)))(function(handler3) {
                  return discard1(queueOrRun(v2.pendingOuts)(handler3(v1.value0)))(function() {
                    return pure7(v1.value1);
                  });
                });
              });
            }
            ;
            if (v1 instanceof Par) {
              return sequential2(retractFreeAp2(hoistFreeAp(function() {
                var $119 = evalM(render9)(ref3);
                return function($120) {
                  return parallel3($119($120));
                };
              }())(v1.value0)));
            }
            ;
            if (v1 instanceof Fork) {
              return bind12(fresh(ForkId)(ref3))(function(fid) {
                return bind12(liftEffect4(read(ref3)))(function(v2) {
                  return bind12(liftEffect4($$new(false)))(function(doneRef) {
                    return bind12(fork3($$finally(liftEffect4(function __do12() {
                      modify_($$delete2(fid))(v2.forks)();
                      return write(true)(doneRef)();
                    }))(evalM(render9)(ref3)(v1.value0))))(function(fiber) {
                      return discard1(liftEffect4(unlessM2(read(doneRef))(modify_(insert12(fid)(fiber))(v2.forks))))(function() {
                        return pure7(v1.value1(fid));
                      });
                    });
                  });
                });
              });
            }
            ;
            if (v1 instanceof Join) {
              return bind12(liftEffect4(read(ref3)))(function(v2) {
                return bind12(liftEffect4(read(v2.forks)))(function(forkMap) {
                  return discard1(traverse_32(joinFiber)(lookup12(v1.value0)(forkMap)))(function() {
                    return pure7(v1.value1);
                  });
                });
              });
            }
            ;
            if (v1 instanceof Kill) {
              return bind12(liftEffect4(read(ref3)))(function(v2) {
                return bind12(liftEffect4(read(v2.forks)))(function(forkMap) {
                  return discard1(traverse_32(killFiber(error("Cancelled")))(lookup12(v1.value0)(forkMap)))(function() {
                    return pure7(v1.value1);
                  });
                });
              });
            }
            ;
            if (v1 instanceof GetRef) {
              return bind12(liftEffect4(read(ref3)))(function(v2) {
                return pure7(v1.value1(lookup22(v1.value0)(v2.refs)));
              });
            }
            ;
            throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 83, column 12 - line 139, column 33): " + [v1.constructor.name]);
          };
        };
        return foldFree2(go2(initRef))(v);
      };
    };
  };
  var evalF = function(render9) {
    return function(ref3) {
      return function(v) {
        if (v instanceof RefUpdate) {
          return liftEffect4(flip(modify_)(ref3)(mapDriverState(function(st) {
            return {
              component: st.component,
              state: st.state,
              children: st.children,
              childrenIn: st.childrenIn,
              childrenOut: st.childrenOut,
              selfRef: st.selfRef,
              handlerRef: st.handlerRef,
              pendingQueries: st.pendingQueries,
              pendingOuts: st.pendingOuts,
              pendingHandlers: st.pendingHandlers,
              rendering: st.rendering,
              fresh: st.fresh,
              subscriptions: st.subscriptions,
              forks: st.forks,
              lifecycleHandlers: st.lifecycleHandlers,
              refs: alter2($$const(v.value1))(v.value0)(st.refs)
            };
          })));
        }
        ;
        if (v instanceof Action) {
          return bind12(liftEffect4(read(ref3)))(function(v1) {
            return evalM(render9)(ref3)(v1["component"]["eval"](new Action2(v.value0, unit)));
          });
        }
        ;
        throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 52, column 20 - line 58, column 62): " + [v.constructor.name]);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Aff.Driver/index.js
  var bind4 = /* @__PURE__ */ bind(bindEffect);
  var discard3 = /* @__PURE__ */ discard(discardUnit);
  var for_2 = /* @__PURE__ */ for_(applicativeEffect)(foldableMaybe);
  var traverse_5 = /* @__PURE__ */ traverse_(applicativeAff)(foldableList);
  var fork4 = /* @__PURE__ */ fork(monadForkAff);
  var bindFlipped7 = /* @__PURE__ */ bindFlipped(bindEffect);
  var traverse_13 = /* @__PURE__ */ traverse_(applicativeEffect);
  var traverse_23 = /* @__PURE__ */ traverse_13(foldableMaybe);
  var traverse_33 = /* @__PURE__ */ traverse_13(foldableMap);
  var discard22 = /* @__PURE__ */ discard3(bindAff);
  var parSequence_3 = /* @__PURE__ */ parSequence_(parallelAff)(applicativeParAff)(foldableList);
  var liftEffect5 = /* @__PURE__ */ liftEffect(monadEffectAff);
  var pure8 = /* @__PURE__ */ pure(applicativeEffect);
  var map18 = /* @__PURE__ */ map(functorEffect);
  var pure12 = /* @__PURE__ */ pure(applicativeAff);
  var when2 = /* @__PURE__ */ when(applicativeEffect);
  var renderStateX2 = /* @__PURE__ */ renderStateX(functorEffect);
  var $$void5 = /* @__PURE__ */ $$void(functorAff);
  var foreachSlot2 = /* @__PURE__ */ foreachSlot(applicativeEffect);
  var renderStateX_2 = /* @__PURE__ */ renderStateX_(applicativeEffect);
  var tailRecM3 = /* @__PURE__ */ tailRecM(monadRecEffect);
  var voidLeft3 = /* @__PURE__ */ voidLeft(functorEffect);
  var bind13 = /* @__PURE__ */ bind(bindAff);
  var liftEffect1 = /* @__PURE__ */ liftEffect(monadEffectEffect);
  var newLifecycleHandlers = /* @__PURE__ */ function() {
    return $$new({
      initializers: Nil.value,
      finalizers: Nil.value
    });
  }();
  var handlePending = function(ref3) {
    return function __do12() {
      var queue = read(ref3)();
      write(Nothing.value)(ref3)();
      return for_2(queue)(function() {
        var $59 = traverse_5(fork4);
        return function($60) {
          return handleAff($59(reverse2($60)));
        };
      }())();
    };
  };
  var cleanupSubscriptionsAndForks = function(v) {
    return function __do12() {
      bindFlipped7(traverse_23(traverse_33(unsubscribe)))(read(v.subscriptions))();
      write(Nothing.value)(v.subscriptions)();
      bindFlipped7(traverse_33(function() {
        var $61 = killFiber(error("finalized"));
        return function($62) {
          return handleAff($61($62));
        };
      }()))(read(v.forks))();
      return write(empty2)(v.forks)();
    };
  };
  var runUI = function(renderSpec2) {
    return function(component10) {
      return function(i2) {
        var squashChildInitializers = function(lchs) {
          return function(preInits) {
            return unDriverStateX(function(st) {
              var parentInitializer = evalM(render9)(st.selfRef)(st["component"]["eval"](new Initialize(unit)));
              return modify_(function(handlers) {
                return {
                  initializers: new Cons(discard22(parSequence_3(reverse2(handlers.initializers)))(function() {
                    return discard22(parentInitializer)(function() {
                      return liftEffect5(function __do12() {
                        handlePending(st.pendingQueries)();
                        return handlePending(st.pendingOuts)();
                      });
                    });
                  }), preInits),
                  finalizers: handlers.finalizers
                };
              })(lchs);
            });
          };
        };
        var runComponent = function(lchs) {
          return function(handler3) {
            return function(j) {
              return unComponent(function(c) {
                return function __do12() {
                  var lchs$prime = newLifecycleHandlers();
                  var $$var2 = initDriverState(c)(j)(handler3)(lchs$prime)();
                  var pre2 = read(lchs)();
                  write({
                    initializers: Nil.value,
                    finalizers: pre2.finalizers
                  })(lchs)();
                  bindFlipped7(unDriverStateX(function() {
                    var $63 = render9(lchs);
                    return function($64) {
                      return $63(function(v) {
                        return v.selfRef;
                      }($64));
                    };
                  }()))(read($$var2))();
                  bindFlipped7(squashChildInitializers(lchs)(pre2.initializers))(read($$var2))();
                  return $$var2;
                };
              });
            };
          };
        };
        var renderChild = function(lchs) {
          return function(handler3) {
            return function(childrenInRef) {
              return function(childrenOutRef) {
                return unComponentSlot(function(slot) {
                  return function __do12() {
                    var childrenIn = map18(slot.pop)(read(childrenInRef))();
                    var $$var2 = function() {
                      if (childrenIn instanceof Just) {
                        write(childrenIn.value0.value1)(childrenInRef)();
                        var dsx = read(childrenIn.value0.value0)();
                        unDriverStateX(function(st) {
                          return function __do13() {
                            flip(write)(st.handlerRef)(function() {
                              var $65 = maybe(pure12(unit))(handler3);
                              return function($66) {
                                return $65(slot.output($66));
                              };
                            }())();
                            return handleAff(evalM(render9)(st.selfRef)(st["component"]["eval"](new Receive(slot.input, unit))))();
                          };
                        })(dsx)();
                        return childrenIn.value0.value0;
                      }
                      ;
                      if (childrenIn instanceof Nothing) {
                        return runComponent(lchs)(function() {
                          var $67 = maybe(pure12(unit))(handler3);
                          return function($68) {
                            return $67(slot.output($68));
                          };
                        }())(slot.input)(slot.component)();
                      }
                      ;
                      throw new Error("Failed pattern match at Halogen.Aff.Driver (line 213, column 14 - line 222, column 98): " + [childrenIn.constructor.name]);
                    }();
                    var isDuplicate = map18(function($69) {
                      return isJust(slot.get($69));
                    })(read(childrenOutRef))();
                    when2(isDuplicate)(warn("Halogen: Duplicate slot address was detected during rendering, unexpected results may occur"))();
                    modify_(slot.set($$var2))(childrenOutRef)();
                    return bind4(read($$var2))(renderStateX2(function(v) {
                      if (v instanceof Nothing) {
                        return $$throw("Halogen internal error: child was not initialized in renderChild");
                      }
                      ;
                      if (v instanceof Just) {
                        return pure8(renderSpec2.renderChild(v.value0));
                      }
                      ;
                      throw new Error("Failed pattern match at Halogen.Aff.Driver (line 227, column 37 - line 229, column 50): " + [v.constructor.name]);
                    }))();
                  };
                });
              };
            };
          };
        };
        var render9 = function(lchs) {
          return function($$var2) {
            return function __do12() {
              var v = read($$var2)();
              var shouldProcessHandlers = map18(isNothing)(read(v.pendingHandlers))();
              when2(shouldProcessHandlers)(write(new Just(Nil.value))(v.pendingHandlers))();
              write(empty3)(v.childrenOut)();
              write(v.children)(v.childrenIn)();
              var handler3 = function() {
                var $70 = queueOrRun(v.pendingHandlers);
                var $71 = evalF(render9)(v.selfRef);
                return function($72) {
                  return $70($$void5($71($72)));
                };
              }();
              var childHandler = function() {
                var $73 = queueOrRun(v.pendingQueries);
                return function($74) {
                  return $73(handler3(Action.create($74)));
                };
              }();
              var rendering = renderSpec2.render(function($75) {
                return handleAff(handler3($75));
              })(renderChild(lchs)(childHandler)(v.childrenIn)(v.childrenOut))(v.component.render(v.state))(v.rendering)();
              var children2 = read(v.childrenOut)();
              var childrenIn = read(v.childrenIn)();
              foreachSlot2(childrenIn)(function(v1) {
                return function __do13() {
                  var childDS = read(v1)();
                  renderStateX_2(renderSpec2.removeChild)(childDS)();
                  return finalize7(lchs)(childDS)();
                };
              })();
              flip(modify_)(v.selfRef)(mapDriverState(function(ds$prime) {
                return {
                  component: ds$prime.component,
                  state: ds$prime.state,
                  refs: ds$prime.refs,
                  childrenIn: ds$prime.childrenIn,
                  childrenOut: ds$prime.childrenOut,
                  selfRef: ds$prime.selfRef,
                  handlerRef: ds$prime.handlerRef,
                  pendingQueries: ds$prime.pendingQueries,
                  pendingOuts: ds$prime.pendingOuts,
                  pendingHandlers: ds$prime.pendingHandlers,
                  fresh: ds$prime.fresh,
                  subscriptions: ds$prime.subscriptions,
                  forks: ds$prime.forks,
                  lifecycleHandlers: ds$prime.lifecycleHandlers,
                  rendering: new Just(rendering),
                  children: children2
                };
              }))();
              return when2(shouldProcessHandlers)(flip(tailRecM3)(unit)(function(v1) {
                return function __do13() {
                  var handlers = read(v.pendingHandlers)();
                  write(new Just(Nil.value))(v.pendingHandlers)();
                  traverse_23(function() {
                    var $76 = traverse_5(fork4);
                    return function($77) {
                      return handleAff($76(reverse2($77)));
                    };
                  }())(handlers)();
                  var mmore = read(v.pendingHandlers)();
                  var $52 = maybe(false)($$null2)(mmore);
                  if ($52) {
                    return voidLeft3(write(Nothing.value)(v.pendingHandlers))(new Done(unit))();
                  }
                  ;
                  return new Loop(unit);
                };
              }))();
            };
          };
        };
        var finalize7 = function(lchs) {
          return unDriverStateX(function(st) {
            return function __do12() {
              cleanupSubscriptionsAndForks(st)();
              var f = evalM(render9)(st.selfRef)(st["component"]["eval"](new Finalize(unit)));
              modify_(function(handlers) {
                return {
                  initializers: handlers.initializers,
                  finalizers: new Cons(f, handlers.finalizers)
                };
              })(lchs)();
              return foreachSlot2(st.children)(function(v) {
                return function __do13() {
                  var dsx = read(v)();
                  return finalize7(lchs)(dsx)();
                };
              })();
            };
          });
        };
        var evalDriver = function(disposed) {
          return function(ref3) {
            return function(q2) {
              return bind13(liftEffect5(read(disposed)))(function(v) {
                if (v) {
                  return pure12(Nothing.value);
                }
                ;
                return evalQ(render9)(ref3)(q2);
              });
            };
          };
        };
        var dispose = function(disposed) {
          return function(lchs) {
            return function(dsx) {
              return handleLifecycle(lchs)(function __do12() {
                var v = read(disposed)();
                if (v) {
                  return unit;
                }
                ;
                write(true)(disposed)();
                finalize7(lchs)(dsx)();
                return unDriverStateX(function(v1) {
                  return function __do13() {
                    var v2 = liftEffect1(read(v1.selfRef))();
                    return for_2(v2.rendering)(renderSpec2.dispose)();
                  };
                })(dsx)();
              });
            };
          };
        };
        return bind13(liftEffect5(newLifecycleHandlers))(function(lchs) {
          return bind13(liftEffect5($$new(false)))(function(disposed) {
            return handleLifecycle(lchs)(function __do12() {
              var sio = create3();
              var dsx = bindFlipped7(read)(runComponent(lchs)(function() {
                var $78 = notify(sio.listener);
                return function($79) {
                  return liftEffect5($78($79));
                };
              }())(i2)(component10))();
              return unDriverStateX(function(st) {
                return pure8({
                  query: evalDriver(disposed)(st.selfRef),
                  messages: sio.emitter,
                  dispose: dispose(disposed)(lchs)(dsx)
                });
              })(dsx)();
            });
          });
        });
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.Node/foreign.js
  var getEffProp2 = function(name15) {
    return function(node) {
      return function() {
        return node[name15];
      };
    };
  };
  var baseURI = getEffProp2("baseURI");
  var _ownerDocument = getEffProp2("ownerDocument");
  var _parentNode = getEffProp2("parentNode");
  var _parentElement = getEffProp2("parentElement");
  var childNodes = getEffProp2("childNodes");
  var _firstChild = getEffProp2("firstChild");
  var _lastChild = getEffProp2("lastChild");
  var _previousSibling = getEffProp2("previousSibling");
  var _nextSibling = getEffProp2("nextSibling");
  var _nodeValue = getEffProp2("nodeValue");
  var textContent = getEffProp2("textContent");
  function contains2(node1) {
    return function(node2) {
      return function() {
        return node1.contains(node2);
      };
    };
  }
  function insertBefore(node1) {
    return function(node2) {
      return function(parent2) {
        return function() {
          parent2.insertBefore(node1, node2);
        };
      };
    };
  }
  function appendChild(node) {
    return function(parent2) {
      return function() {
        parent2.appendChild(node);
      };
    };
  }
  function removeChild2(node) {
    return function(parent2) {
      return function() {
        parent2.removeChild(node);
      };
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.Node/index.js
  var map19 = /* @__PURE__ */ map(functorEffect);
  var parentNode2 = /* @__PURE__ */ function() {
    var $6 = map19(toMaybe);
    return function($7) {
      return $6(_parentNode($7));
    };
  }();
  var nextSibling = /* @__PURE__ */ function() {
    var $15 = map19(toMaybe);
    return function($16) {
      return $15(_nextSibling($16));
    };
  }();
  var fromEventTarget = /* @__PURE__ */ unsafeReadProtoTagged("Node");
  var firstChild = /* @__PURE__ */ function() {
    var $25 = map19(toMaybe);
    return function($26) {
      return $25(_firstChild($26));
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.VDom.Driver/index.js
  var $runtime_lazy8 = function(name15, moduleName, init2) {
    var state3 = 0;
    var val;
    return function(lineNumber) {
      if (state3 === 2) return val;
      if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state3 = 1;
      val = init2();
      state3 = 2;
      return val;
    };
  };
  var $$void6 = /* @__PURE__ */ $$void(functorEffect);
  var pure9 = /* @__PURE__ */ pure(applicativeEffect);
  var traverse_6 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableMaybe);
  var unwrap3 = /* @__PURE__ */ unwrap();
  var when3 = /* @__PURE__ */ when(applicativeEffect);
  var not2 = /* @__PURE__ */ not(/* @__PURE__ */ heytingAlgebraFunction(/* @__PURE__ */ heytingAlgebraFunction(heytingAlgebraBoolean)));
  var identity8 = /* @__PURE__ */ identity(categoryFn);
  var bind14 = /* @__PURE__ */ bind(bindAff);
  var liftEffect6 = /* @__PURE__ */ liftEffect(monadEffectAff);
  var map20 = /* @__PURE__ */ map(functorEffect);
  var bindFlipped8 = /* @__PURE__ */ bindFlipped(bindEffect);
  var substInParent = function(v) {
    return function(v1) {
      return function(v2) {
        if (v1 instanceof Just && v2 instanceof Just) {
          return $$void6(insertBefore(v)(v1.value0)(v2.value0));
        }
        ;
        if (v1 instanceof Nothing && v2 instanceof Just) {
          return $$void6(appendChild(v)(v2.value0));
        }
        ;
        return pure9(unit);
      };
    };
  };
  var removeChild3 = function(v) {
    return function __do12() {
      var npn = parentNode2(v.node)();
      return traverse_6(function(pn) {
        return removeChild2(v.node)(pn);
      })(npn)();
    };
  };
  var mkSpec = function(handler3) {
    return function(renderChildRef) {
      return function(document2) {
        var getNode = unRenderStateX(function(v) {
          return v.node;
        });
        var done = function(st) {
          if (st instanceof Just) {
            return halt(st.value0);
          }
          ;
          return unit;
        };
        var buildWidget2 = function(spec) {
          var buildThunk2 = buildThunk(unwrap3)(spec);
          var $lazy_patch = $runtime_lazy8("patch", "Halogen.VDom.Driver", function() {
            return function(st, slot) {
              if (st instanceof Just) {
                if (slot instanceof ComponentSlot) {
                  halt(st.value0);
                  return $lazy_renderComponentSlot(100)(slot.value0);
                }
                ;
                if (slot instanceof ThunkSlot) {
                  var step$prime = step2(st.value0, slot.value0);
                  return mkStep(new Step(extract2(step$prime), new Just(step$prime), $lazy_patch(103), done));
                }
                ;
                throw new Error("Failed pattern match at Halogen.VDom.Driver (line 97, column 22 - line 103, column 79): " + [slot.constructor.name]);
              }
              ;
              return $lazy_render(104)(slot);
            };
          });
          var $lazy_render = $runtime_lazy8("render", "Halogen.VDom.Driver", function() {
            return function(slot) {
              if (slot instanceof ComponentSlot) {
                return $lazy_renderComponentSlot(86)(slot.value0);
              }
              ;
              if (slot instanceof ThunkSlot) {
                var step4 = buildThunk2(slot.value0);
                return mkStep(new Step(extract2(step4), new Just(step4), $lazy_patch(89), done));
              }
              ;
              throw new Error("Failed pattern match at Halogen.VDom.Driver (line 84, column 7 - line 89, column 75): " + [slot.constructor.name]);
            };
          });
          var $lazy_renderComponentSlot = $runtime_lazy8("renderComponentSlot", "Halogen.VDom.Driver", function() {
            return function(cs) {
              var renderChild = read(renderChildRef)();
              var rsx = renderChild(cs)();
              var node = getNode(rsx);
              return mkStep(new Step(node, Nothing.value, $lazy_patch(117), done));
            };
          });
          var patch = $lazy_patch(91);
          var render9 = $lazy_render(82);
          var renderComponentSlot = $lazy_renderComponentSlot(109);
          return render9;
        };
        var buildAttributes = buildProp(handler3);
        return {
          buildWidget: buildWidget2,
          buildAttributes,
          document: document2
        };
      };
    };
  };
  var renderSpec = function(document2) {
    return function(container) {
      var render9 = function(handler3) {
        return function(child) {
          return function(v) {
            return function(v1) {
              if (v1 instanceof Nothing) {
                return function __do12() {
                  var renderChildRef = $$new(child)();
                  var spec = mkSpec(handler3)(renderChildRef)(document2);
                  var machine = buildVDom(spec)(v);
                  var node = extract2(machine);
                  $$void6(appendChild(node)(toNode(container)))();
                  return {
                    machine,
                    node,
                    renderChildRef
                  };
                };
              }
              ;
              if (v1 instanceof Just) {
                return function __do12() {
                  write(child)(v1.value0.renderChildRef)();
                  var parent2 = parentNode2(v1.value0.node)();
                  var nextSib = nextSibling(v1.value0.node)();
                  var machine$prime = step2(v1.value0.machine, v);
                  var newNode = extract2(machine$prime);
                  when3(not2(unsafeRefEq)(v1.value0.node)(newNode))(substInParent(newNode)(nextSib)(parent2))();
                  return {
                    machine: machine$prime,
                    node: newNode,
                    renderChildRef: v1.value0.renderChildRef
                  };
                };
              }
              ;
              throw new Error("Failed pattern match at Halogen.VDom.Driver (line 157, column 5 - line 173, column 80): " + [v1.constructor.name]);
            };
          };
        };
      };
      return {
        render: render9,
        renderChild: identity8,
        removeChild: removeChild3,
        dispose: removeChild3
      };
    };
  };
  var runUI2 = function(component10) {
    return function(i2) {
      return function(element3) {
        return bind14(liftEffect6(map20(toDocument)(bindFlipped8(document)(windowImpl))))(function(document2) {
          return runUI(renderSpec(document2)(element3))(component10)(i2);
        });
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.Event.Event/foreign.js
  function _target(e) {
    return e.target;
  }
  function preventDefault(e) {
    return function() {
      return e.preventDefault();
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.Event.Event/index.js
  var target5 = function($3) {
    return toMaybe(_target($3));
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.FocusEvent.EventTypes/index.js
  var focus2 = "focus";

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.KeyboardEvent.EventTypes/index.js
  var keydown = "keydown";

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.MouseEvent.EventTypes/index.js
  var mouseleave = "mouseleave";
  var mouseenter = "mouseenter";
  var click2 = "click";

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.HTML.Events/index.js
  var mouseHandler = unsafeCoerce2;
  var keyHandler = unsafeCoerce2;
  var handler2 = function(et) {
    return function(f) {
      return handler(et)(function(ev) {
        return new Just(new Action(f(ev)));
      });
    };
  };
  var onClick = /* @__PURE__ */ function() {
    var $15 = handler2(click2);
    return function($16) {
      return $15(mouseHandler($16));
    };
  }();
  var onKeyDown = /* @__PURE__ */ function() {
    var $23 = handler2(keydown);
    return function($24) {
      return $23(keyHandler($24));
    };
  }();
  var onMouseEnter = /* @__PURE__ */ function() {
    var $29 = handler2(mouseenter);
    return function($30) {
      return $29(mouseHandler($30));
    };
  }();
  var onMouseLeave = /* @__PURE__ */ function() {
    var $31 = handler2(mouseleave);
    return function($32) {
      return $31(mouseHandler($32));
    };
  }();
  var focusHandler = unsafeCoerce2;
  var onBlur = /* @__PURE__ */ function() {
    var $55 = handler2(blur2);
    return function($56) {
      return $55(focusHandler($56));
    };
  }();
  var onFocus = /* @__PURE__ */ function() {
    var $57 = handler2(focus2);
    return function($58) {
      return $57(focusHandler($58));
    };
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Behavior.ControllableState/index.js
  var sync = function(controlled) {
    return function(c) {
      return {
        uncontrolled: c.uncontrolled,
        controlled
      };
    };
  };
  var isControlled = function(c) {
    return isJust(c.controlled);
  };
  var current = function(c) {
    return fromMaybe(c.uncontrolled)(c.controlled);
  };
  var controllable = function(controlled) {
    return function(defaultValue4) {
      return {
        controlled,
        uncontrolled: defaultValue4
      };
    };
  };
  var change2 = function(v) {
    return function(c) {
      return {
        next: function() {
          var $2 = isControlled(c);
          if ($2) {
            return c;
          }
          ;
          return {
            controlled: c.controlled,
            uncontrolled: v
          };
        }(),
        emit: v
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Halogen.Query.Event/index.js
  var traverse_7 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableMaybe);
  var eventListener2 = function(eventType) {
    return function(target6) {
      return function(f) {
        return makeEmitter(function(push2) {
          return function __do12() {
            var listener = eventListener(function(ev) {
              return traverse_7(push2)(f(ev));
            })();
            addEventListener(eventType)(listener)(false)(target6)();
            return removeEventListener(eventType)(listener)(false)(target6);
          };
        });
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.KeyboardEvent/foreign.js
  function key(e) {
    return e.key;
  }
  function shiftKey(e) {
    return e.shiftKey;
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.KeyboardEvent/index.js
  var toEvent = unsafeCoerce2;
  var fromEvent = /* @__PURE__ */ unsafeReadProtoTagged("KeyboardEvent");

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Behavior.DismissableLayer/index.js
  var bind5 = /* @__PURE__ */ bind(bindMaybe);
  var pure10 = /* @__PURE__ */ pure(applicativeEffect);
  var map21 = /* @__PURE__ */ map(functorEffect);
  var not3 = /* @__PURE__ */ not(heytingAlgebraBoolean);
  var pointerDown = function(target6) {
    return function(f) {
      return eventListener2("pointerdown")(target6)(function($10) {
        return Just.create(f($10));
      });
    };
  };
  var isOutside = function(content3) {
    return function(e) {
      var v = bind5(target5(e))(fromEventTarget);
      if (v instanceof Nothing) {
        return pure10(true);
      }
      ;
      if (v instanceof Just) {
        return map21(not3)(contains2(content3)(v.value0));
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Behavior.DismissableLayer (line 56, column 3 - line 58, column 47): " + [v.constructor.name]);
    };
  };
  var $$escape = function(target6) {
    return function(onEscape) {
      return eventListener2(keydown)(target6)(function(e) {
        return bind5(fromEvent(e))(function(ke) {
          var $9 = key(ke) === "Escape";
          if ($9) {
            return new Just(onEscape);
          }
          ;
          return Nothing.value;
        });
      });
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Foundation.Dom/foreign.js
  var computedStyle = (el2) => (prop4) => () => window.getComputedStyle(el2).getPropertyValue(prop4);
  var setInlineStyle = (el2) => (prop4) => (value12) => () => {
    el2.style.setProperty(prop4, value12);
  };
  var queueMicrotask_ = (eff) => () => {
    queueMicrotask(eff);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Foundation.Dom/index.js
  var queueMicrotask2 = queueMicrotask_;

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.NodeList/foreign.js
  function toArray(list) {
    return function() {
      return [].slice.call(list);
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Behavior.FocusScope/index.js
  var bind6 = /* @__PURE__ */ bind(bindEffect);
  var pure11 = /* @__PURE__ */ pure(applicativeEffect);
  var filterA2 = /* @__PURE__ */ filterA(applicativeEffect);
  var when4 = /* @__PURE__ */ when(applicativeEffect);
  var visible = function(el2) {
    return function __do12() {
      var vis = computedStyle(el2)("visibility")();
      var disp = computedStyle(el2)("display")();
      return vis !== "hidden" && disp !== "none";
    };
  };
  var tabbableSelector = /* @__PURE__ */ function() {
    return 'a[href], button:not([disabled]), input:not([disabled]):not([type=hidden]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"]):not([disabled])';
  }();
  var tabbables = function(container) {
    return function __do12() {
      var nl = querySelectorAll(tabbableSelector)(toParentNode2(container))();
      var nodes = toArray(nl)();
      return filterA2(visible)(mapMaybe(fromNode)(nodes))();
    };
  };
  var tabLoop = function(loop2) {
    return function(container) {
      return function(ke) {
        var $13 = key(ke) !== "Tab";
        if ($13) {
          return pure11(false);
        }
        ;
        return function __do12() {
          var ts = tabbables(container)();
          var v = last(ts);
          var v1 = head(ts);
          if (v1 instanceof Just && v instanceof Just) {
            var doc = bind6(windowImpl)(document)();
            var active = activeElement(doc)();
            var atLast = maybe(false)(function(a2) {
              return unsafeRefEq(a2)(v.value0);
            })(active);
            var atFirst = maybe(false)(function(a2) {
              return unsafeRefEq(a2)(v1.value0);
            })(active);
            var $16 = !shiftKey(ke) && atLast;
            if ($16) {
              when4(loop2)(focus(v1.value0))();
              return loop2;
            }
            ;
            var $17 = shiftKey(ke) && atFirst;
            if ($17) {
              when4(loop2)(focus(v.value0))();
              return loop2;
            }
            ;
            return false;
          }
          ;
          return false;
        };
      };
    };
  };
  var captureFocus = function(container) {
    return function __do12() {
      var doc = bind6(windowImpl)(document)();
      var prev = activeElement(doc)();
      var ts = tabbables(container)();
      (function() {
        var v = head(ts);
        if (v instanceof Just) {
          return focus(v.value0)();
        }
        ;
        if (v instanceof Nothing) {
          return focus(container)();
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Radix.Behavior.FocusScope (line 70, column 3 - line 72, column 43): " + [v.constructor.name]);
      })();
      return maybe(pure11(unit))(focus)(prev);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Behavior.Id/index.js
  var mapFlipped2 = /* @__PURE__ */ mapFlipped(functorEffect);
  var show2 = /* @__PURE__ */ show(showInt);
  var counter = /* @__PURE__ */ unsafePerformEffect(/* @__PURE__ */ $$new(0));
  var useId = function(dictMonadEffect) {
    return liftEffect(dictMonadEffect)(mapFlipped2(modify(function(v) {
      return v + 1 | 0;
    })(counter))(function(n) {
      return "radix-" + show2(n);
    }));
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.Document/foreign.js
  var getEffProp3 = function(name15) {
    return function(doc) {
      return function() {
        return doc[name15];
      };
    };
  };
  var url = getEffProp3("URL");
  var documentURI = getEffProp3("documentURI");
  var origin2 = getEffProp3("origin");
  var compatMode = getEffProp3("compatMode");
  var characterSet = getEffProp3("characterSet");
  var contentType = getEffProp3("contentType");
  var _documentElement2 = getEffProp3("documentElement");
  function createElement2(localName2) {
    return function(doc) {
      return function() {
        return doc.createElement(localName2);
      };
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.DOM.HTMLCollection/foreign.js
  function toArray2(list) {
    return function() {
      return [].slice.call(list);
    };
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Foundation.Envelope/index.js
  var bind7 = /* @__PURE__ */ bind(bindEffect);
  var for_3 = /* @__PURE__ */ for_(applicativeEffect);
  var for_1 = /* @__PURE__ */ for_3(foldableMaybe);
  var max6 = /* @__PURE__ */ max(ordInt);
  var when5 = /* @__PURE__ */ when(applicativeEffect);
  var mapFlipped3 = /* @__PURE__ */ mapFlipped(functorMaybe);
  var for_22 = /* @__PURE__ */ for_3(foldableArray);
  var applySecond2 = /* @__PURE__ */ applySecond(applyEffect);
  var traverse_8 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableMaybe);
  var withBody = function(f) {
    return function __do12() {
      var doc = bind7(windowImpl)(document)();
      var mbody = body(doc)();
      return for_1(mbody)(f)();
    };
  };
  var scrollDepth = /* @__PURE__ */ unsafePerformEffect(/* @__PURE__ */ $$new(0));
  var unlockScroll = function __do2() {
    var n = read(scrollDepth)();
    var n$prime = max6(0)(n - 1 | 0);
    write(n$prime)(scrollDepth)();
    return when5(n$prime === 0)(withBody(function(body3) {
      return function __do12() {
        removeAttribute2("data-scroll-locked")(toElement(body3))();
        return setInlineStyle(body3)("pointer-events")("")();
      };
    }))();
  };
  var lockScroll = function __do3() {
    var n = read(scrollDepth)();
    write(n + 1 | 0)(scrollDepth)();
    return when5(n === 0)(withBody(function(body3) {
      return function __do12() {
        setAttribute2("data-scroll-locked")("1")(toElement(body3))();
        return setInlineStyle(body3)("pointer-events")("none")();
      };
    }))();
  };
  var guardStyle = "outline: none; opacity: 0; position: fixed; pointer-events: none;";
  var mkGuard = function(doc) {
    return function __do12() {
      var el2 = createElement2("span")(doc)();
      setAttribute2("data-radix-focus-guard")("")(el2)();
      setAttribute2("tabindex")("0")(el2)();
      setAttribute2("style")(guardStyle)(el2)();
      return el2;
    };
  };
  var guardEls = /* @__PURE__ */ function() {
    return unsafePerformEffect($$new(Nothing.value));
  }();
  var reAdoptBeforeTrail = function(wrap3) {
    return function __do12() {
      var mg = read(guardEls)();
      return withBody(function(body3) {
        var wrapNode = toNode(wrap3);
        var bodyNode = toNode(body3);
        if (mg instanceof Just) {
          return insertBefore(wrapNode)(toNode2(mg.value0.trail))(bodyNode);
        }
        ;
        if (mg instanceof Nothing) {
          return appendChild(wrapNode)(bodyNode);
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Radix.Foundation.Envelope (line 141, column 5 - line 143, column 47): " + [mg.constructor.name]);
      })();
    };
  };
  var guardDepth = /* @__PURE__ */ unsafePerformEffect(/* @__PURE__ */ $$new(0));
  var removeFocusGuards = function __do4() {
    var n = read(guardDepth)();
    var n$prime = max6(0)(n - 1 | 0);
    write(n$prime)(guardDepth)();
    return when5(n$prime === 0)(function __do12() {
      var mg = read(guardEls)();
      for_1(mg)(function(v) {
        return withBody(function(body3) {
          var bodyNode = toNode(body3);
          return function __do13() {
            removeChild2(toNode2(v.lead))(bodyNode)();
            return removeChild2(toNode2(v.trail))(bodyNode)();
          };
        });
      })();
      return write(Nothing.value)(guardEls)();
    })();
  };
  var documentEl = function __do5() {
    var hdoc = bind7(windowImpl)(document)();
    var mbody = body(hdoc)();
    return mapFlipped3(mbody)(function(body3) {
      return {
        doc: toDocument(hdoc),
        body: body3
      };
    });
  };
  var bodyChildren = function __do6() {
    var hdoc = bind7(windowImpl)(document)();
    var mbody = body(hdoc)();
    if (mbody instanceof Nothing) {
      return [];
    }
    ;
    if (mbody instanceof Just) {
      return bind7(children(toParentNode3(toElement(mbody.value0))))(toArray2)();
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Radix.Foundation.Envelope (line 150, column 3 - line 152, column 90): " + [mbody.constructor.name]);
  };
  var hideOthers = function(keep) {
    return function __do12() {
      var els = bodyChildren();
      var keepEl = toElement(keep);
      return for_22(filter(function(e) {
        return !unsafeRefEq(e)(keepEl);
      })(els))(function(e) {
        return function __do13() {
          setAttribute2("aria-hidden")("true")(e)();
          return setAttribute2("data-aria-hidden")("true")(e)();
        };
      })();
    };
  };
  var showOthers = function __do7() {
    var els = bodyChildren();
    return for_22(els)(function(e) {
      return function __do12() {
        var m = getAttribute("data-aria-hidden")(e)();
        if (m instanceof Just) {
          return applySecond2(removeAttribute2("aria-hidden")(e))(removeAttribute2("data-aria-hidden")(e))();
        }
        ;
        if (m instanceof Nothing) {
          return unit;
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Radix.Foundation.Envelope (line 170, column 5 - line 172, column 27): " + [m.constructor.name]);
      };
    })();
  };
  var addFocusGuards = function __do8() {
    var n = read(guardDepth)();
    write(n + 1 | 0)(guardDepth)();
    return when5(n === 0)(bind7(documentEl)(traverse_8(function(v) {
      var bodyNode = toNode(v.body);
      return function __do12() {
        var lead = mkGuard(v.doc)();
        var trail = mkGuard(v.doc)();
        var mfirst = firstChild(bodyNode)();
        (function() {
          if (mfirst instanceof Just) {
            return insertBefore(toNode2(lead))(mfirst.value0)(bodyNode)();
          }
          ;
          if (mfirst instanceof Nothing) {
            return appendChild(toNode2(lead))(bodyNode)();
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Radix.Foundation.Envelope (line 112, column 5 - line 114, column 52): " + [mfirst.constructor.name]);
        })();
        appendChild(toNode2(trail))(bodyNode)();
        return write(new Just({
          lead,
          trail
        }))(guardEls)();
      };
    })))();
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Foundation.Portal/index.js
  var bind8 = /* @__PURE__ */ bind(bindEffect);
  var map23 = /* @__PURE__ */ map(functorEffect);
  var map110 = /* @__PURE__ */ map(functorMaybe);
  var $$void7 = /* @__PURE__ */ $$void(functorEffect);
  var documentBody = function __do9() {
    var doc = bind8(windowImpl)(document)();
    return map23(map110(toElement))(body(doc))();
  };
  var afterFrame = function(eff) {
    return function __do12() {
      var w = windowImpl();
      return $$void7(requestAnimationFrame(eff)(w))();
    };
  };
  var adopt = function(container) {
    return function(node) {
      var n = toNode2(node);
      var c = toNode2(container);
      return function __do12() {
        var v = parentNode2(n)();
        if (v instanceof Just && unsafeRefEq(v.value0)(c)) {
          return unit;
        }
        ;
        return appendChild(n)(c)();
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Foundation.Style/index.js
  var map24 = /* @__PURE__ */ map(functorArray);
  var Top = /* @__PURE__ */ function() {
    function Top2() {
    }
    ;
    Top2.value = new Top2();
    return Top2;
  }();
  var Right2 = /* @__PURE__ */ function() {
    function Right3() {
    }
    ;
    Right3.value = new Right3();
    return Right3;
  }();
  var Bottom = /* @__PURE__ */ function() {
    function Bottom2() {
    }
    ;
    Bottom2.value = new Bottom2();
    return Bottom2;
  }();
  var Left2 = /* @__PURE__ */ function() {
    function Left3() {
    }
    ;
    Left3.value = new Left3();
    return Left3;
  }();
  var Horizontal = /* @__PURE__ */ function() {
    function Horizontal2() {
    }
    ;
    Horizontal2.value = new Horizontal2();
    return Horizontal2;
  }();
  var Vertical = /* @__PURE__ */ function() {
    function Vertical2() {
    }
    ;
    Vertical2.value = new Vertical2();
    return Vertical2;
  }();
  var Start = /* @__PURE__ */ function() {
    function Start2() {
    }
    ;
    Start2.value = new Start2();
    return Start2;
  }();
  var Center = /* @__PURE__ */ function() {
    function Center2() {
    }
    ;
    Center2.value = new Center2();
    return Center2;
  }();
  var End = /* @__PURE__ */ function() {
    function End2() {
    }
    ;
    End2.value = new End2();
    return End2;
  }();
  var sideName = function(v) {
    if (v instanceof Top) {
      return "top";
    }
    ;
    if (v instanceof Right2) {
      return "right";
    }
    ;
    if (v instanceof Bottom) {
      return "bottom";
    }
    ;
    if (v instanceof Left2) {
      return "left";
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Radix.Foundation.Style (line 149, column 12 - line 153, column 17): " + [v.constructor.name]);
  };
  var role = /* @__PURE__ */ attr2("role");
  var eqSide = {
    eq: function(x) {
      return function(y) {
        if (x instanceof Top && y instanceof Top) {
          return true;
        }
        ;
        if (x instanceof Right2 && y instanceof Right2) {
          return true;
        }
        ;
        if (x instanceof Bottom && y instanceof Bottom) {
          return true;
        }
        ;
        if (x instanceof Left2 && y instanceof Left2) {
          return true;
        }
        ;
        return false;
      };
    }
  };
  var eqOrientation = {
    eq: function(x) {
      return function(y) {
        if (x instanceof Horizontal && y instanceof Horizontal) {
          return true;
        }
        ;
        if (x instanceof Vertical && y instanceof Vertical) {
          return true;
        }
        ;
        return false;
      };
    }
  };
  var eqAlign = {
    eq: function(x) {
      return function(y) {
        if (x instanceof Start && y instanceof Start) {
          return true;
        }
        ;
        if (x instanceof Center && y instanceof Center) {
          return true;
        }
        ;
        if (x instanceof End && y instanceof End) {
          return true;
        }
        ;
        return false;
      };
    }
  };
  var dataAttr = function(name15) {
    return function(val) {
      return attr2("data-" + name15)(val);
    };
  };
  var dataState = /* @__PURE__ */ dataAttr("state");
  var cn = function(s) {
    return filter(function(v) {
      return v !== "";
    })(map24(trim)(split(" ")(s)));
  };
  var classes2 = function(v) {
    return classes(map24(ClassName)(v));
  };
  var aria = function(name15) {
    return function(val) {
      return attr2("aria-" + name15)(val);
    };
  };
  var alignName = function(v) {
    if (v instanceof Start) {
      return "start";
    }
    ;
    if (v instanceof Center) {
      return "center";
    }
    ;
    if (v instanceof End) {
      return "end";
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Radix.Foundation.Style (line 168, column 13 - line 171, column 15): " + [v.constructor.name]);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.AlertDialog/index.js
  var bind9 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight2 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard4 = /* @__PURE__ */ discard(discardUnit);
  var discard12 = /* @__PURE__ */ discard4(bindHalogenM);
  var pure13 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map25 = /* @__PURE__ */ map(functorArray);
  var get2 = /* @__PURE__ */ get(monadStateHalogenM);
  var when6 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind15 = /* @__PURE__ */ bind(bindEffect);
  var modify_3 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var map111 = /* @__PURE__ */ map(functorHalogenM);
  var for_4 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var applySecond3 = /* @__PURE__ */ applySecond(applyEffect);
  var $$void8 = /* @__PURE__ */ $$void(functorEffect);
  var append12 = /* @__PURE__ */ append(semigroupArray);
  var type_19 = /* @__PURE__ */ type_17(isPropButtonType);
  var show3 = /* @__PURE__ */ show(showBoolean);
  var SetOpen = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var Initialize2 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive2 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var TriggerClicked = /* @__PURE__ */ function() {
    function TriggerClicked6() {
    }
    ;
    TriggerClicked6.value = new TriggerClicked6();
    return TriggerClicked6;
  }();
  var ContentKeyDown = /* @__PURE__ */ function() {
    function ContentKeyDown4(value0) {
      this.value0 = value0;
    }
    ;
    ContentKeyDown4.create = function(value0) {
      return new ContentKeyDown4(value0);
    };
    return ContentKeyDown4;
  }();
  var EscapePressed = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var AfterOpen = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var scheduleAfterOpen = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind9(liftEffect7(create3))(function(v) {
      return bind9(subscribe2(voidRight2(AfterOpen.value)(v.emitter)))(function(sid) {
        return discard12(liftEffect7(afterFrame(notify(v.listener)(unit))))(function() {
          return pure13(sid);
        });
      });
    });
  };
  var roleAttr = /* @__PURE__ */ attr2("role");
  var portalRef = "rdx-alert-dialog-portal";
  var portalData = /* @__PURE__ */ map25(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var openDialog = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen(dictMonadEffect);
    return bind9(get2)(function(st) {
      return when6(!current(st.ctrl))(bind9(liftEffect7(bind15(windowImpl)(document)))(function(doc) {
        return bind9(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard12(modify_3(function(v) {
            var $62 = {};
            for (var $63 in v) {
              if ({}.hasOwnProperty.call(v, $63)) {
                $62[$63] = v[$63];
              }
              ;
            }
            ;
            $62.ctrl = change2(true)(st.ctrl).next;
            $62.restoreEl = mprev;
            return $62;
          }))(function() {
            return discard12(raise(new OpenChanged(true)))(function() {
              return bind9(function() {
                if (st.closeOnEscape) {
                  return map111(Just.create)(subscribe2($$escape(toEventTarget(doc))(EscapePressed.value)));
                }
                ;
                return pure13(Nothing.value);
              }())(function(sub3) {
                return bind9(scheduleAfterOpen1)(function(psid) {
                  return modify_3(function(v) {
                    var $66 = {};
                    for (var $67 in v) {
                      if ({}.hasOwnProperty.call(v, $67)) {
                        $66[$67] = v[$67];
                      }
                      ;
                    }
                    ;
                    $66.escSub = sub3;
                    $66.postSub = new Just(psid);
                    $66.locked = true;
                    return $66;
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var initialState = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      closeOnEscape: input3.closeOnEscape,
      style: input3.style,
      trigger: input3.trigger,
      title: input3.title,
      description: input3.description,
      content: input3.content,
      contentStyle: input3.contentStyle,
      triggerAttrs: input3.triggerAttrs,
      portalAttrs: input3.portalAttrs,
      restoreEl: Nothing.value,
      escSub: Nothing.value,
      postSub: Nothing.value,
      locked: false,
      contentId: "",
      titleId: "",
      descriptionId: ""
    };
  };
  var defaultStyle = {
    trigger: /* @__PURE__ */ cn("rdx-alert-dialog-trigger"),
    overlay: /* @__PURE__ */ cn("rdx-alert-dialog-overlay"),
    scroll: /* @__PURE__ */ cn("rdx-alert-dialog-scroll"),
    scrollPadding: /* @__PURE__ */ cn("rdx-alert-dialog-scroll-padding"),
    content: /* @__PURE__ */ cn("rdx-alert-dialog-content"),
    title: /* @__PURE__ */ cn("rdx-alert-dialog-title"),
    description: /* @__PURE__ */ cn("rdx-alert-dialog-description")
  };
  var defaultInput = /* @__PURE__ */ function() {
    return {
      open: Nothing.value,
      defaultOpen: false,
      closeOnEscape: true,
      style: defaultStyle,
      trigger: [],
      title: [],
      description: [],
      content: [],
      contentStyle: "",
      triggerAttrs: [],
      portalAttrs: []
    };
  }();
  var contentRef = "rdx-alert-dialog-content";
  var closeDialog = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind9(get2)(function(st) {
      return when6(current(st.ctrl))(discard12(for_4(st.escSub)(unsubscribe2))(function() {
        return discard12(for_4(st.postSub)(unsubscribe2))(function() {
          return discard12(for_4(st.restoreEl)(function($99) {
            return liftEffect7(focus($99));
          }))(function() {
            return discard12(when6(st.locked)(liftEffect7(applySecond3(applySecond3(showOthers)(removeFocusGuards))(unlockScroll))))(function() {
              return discard12(modify_3(function(v) {
                var $69 = {};
                for (var $70 in v) {
                  if ({}.hasOwnProperty.call(v, $70)) {
                    $69[$70] = v[$70];
                  }
                  ;
                }
                ;
                $69.ctrl = change2(false)(st.ctrl).next;
                $69.restoreEl = Nothing.value;
                $69.escSub = Nothing.value;
                $69.postSub = Nothing.value;
                $69.locked = false;
                return $69;
              }))(function() {
                return raise(new OpenChanged(false));
              });
            });
          });
        });
      }));
    });
  };
  var handleAction = function(dictMonadEffect) {
    var monadEffectHalogenM2 = monadEffectHalogenM(dictMonadEffect);
    var useId2 = useId(monadEffectHalogenM2);
    var openDialog1 = openDialog(dictMonadEffect);
    var closeDialog1 = closeDialog(dictMonadEffect);
    var liftEffect7 = liftEffect(monadEffectHalogenM2);
    return function(v) {
      if (v instanceof Initialize2) {
        return bind9(useId2)(function(cid) {
          return bind9(useId2)(function(tid) {
            return bind9(useId2)(function(did) {
              return modify_3(function(v1) {
                var $73 = {};
                for (var $74 in v1) {
                  if ({}.hasOwnProperty.call(v1, $74)) {
                    $73[$74] = v1[$74];
                  }
                  ;
                }
                ;
                $73.contentId = cid;
                $73.titleId = tid;
                $73.descriptionId = did;
                return $73;
              });
            });
          });
        });
      }
      ;
      if (v instanceof Receive2) {
        return modify_3(function(st) {
          var $76 = {};
          for (var $77 in st) {
            if ({}.hasOwnProperty.call(st, $77)) {
              $76[$77] = st[$77];
            }
            ;
          }
          ;
          $76.ctrl = sync(v.value0.open)(st.ctrl);
          $76.closeOnEscape = v.value0.closeOnEscape;
          $76.style = v.value0.style;
          $76.trigger = v.value0.trigger;
          $76.title = v.value0.title;
          $76.description = v.value0.description;
          $76.content = v.value0.content;
          $76.contentStyle = v.value0.contentStyle;
          $76.triggerAttrs = v.value0.triggerAttrs;
          $76.portalAttrs = v.value0.portalAttrs;
          return $76;
        });
      }
      ;
      if (v instanceof TriggerClicked) {
        return openDialog1;
      }
      ;
      if (v instanceof EscapePressed) {
        return bind9(get2)(function(st) {
          return when6(st.closeOnEscape)(closeDialog1);
        });
      }
      ;
      if (v instanceof ContentKeyDown) {
        return bind9(getHTMLElementRef(contentRef))(function(mnode) {
          return for_4(mnode)(function(node) {
            return bind9(liftEffect7(tabLoop(true)(node)(v.value0)))(function(handled) {
              return when6(handled)(liftEffect7(preventDefault(toEvent(v.value0))));
            });
          });
        });
      }
      ;
      if (v instanceof AfterOpen) {
        return bind9(liftEffect7(documentBody))(function(mbody) {
          return bind9(getHTMLElementRef(portalRef))(function(mwrap) {
            return discard12(function() {
              if (mbody instanceof Just && mwrap instanceof Just) {
                return liftEffect7(adopt(mbody.value0)(toElement(mwrap.value0)));
              }
              ;
              return pure13(unit);
            }())(function() {
              return bind9(getHTMLElementRef(contentRef))(function(mnode) {
                return discard12(for_4(mnode)(function(node) {
                  return liftEffect7($$void8(captureFocus(node)));
                }))(function() {
                  return for_4(mwrap)(function(wrap3) {
                    return liftEffect7(function __do12() {
                      lockScroll();
                      addFocusGuards();
                      return hideOthers(wrap3)();
                    });
                  });
                });
              });
            });
          });
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.AlertDialog (line 281, column 16 - line 326, column 31): " + [v.constructor.name]);
    };
  };
  var handleQuery = function(dictMonadEffect) {
    var openDialog1 = openDialog(dictMonadEffect);
    var closeDialog1 = closeDialog(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen) {
        return discard12(function() {
          if (v.value0) {
            return openDialog1;
          }
          ;
          return closeDialog1;
        }())(function() {
          return pure13(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen) {
        return bind9(get2)(function(st) {
          return pure13(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.AlertDialog (line 367, column 15 - line 373, column 42): " + [v.constructor.name]);
    };
  };
  var aria2 = function(name15) {
    return function(val) {
      return attr2("aria-" + name15)(val);
    };
  };
  var overlayContent = function(open) {
    return function(st) {
      return div3(append12([ref2(portalRef), classes2(st.style.overlay), dataState(function() {
        if (open) {
          return "open";
        }
        ;
        return "closed";
      }()), style(function() {
        if (open) {
          return "pointer-events: auto;";
        }
        ;
        return "display:none;";
      }())])(portalData(st.portalAttrs)))([div3([classes2(st.style.scroll)])([div3([classes2(st.style.scrollPadding)])([div3(append12([ref2(contentRef), id2(st.contentId), classes2(st.style.content), roleAttr("alertdialog"), dataState(function() {
        if (open) {
          return "open";
        }
        ;
        return "closed";
      }()), tabIndex2(-1 | 0), style(st.contentStyle), onKeyDown(ContentKeyDown.create)])(append12(function() {
        var $93 = $$null(st.title);
        if ($93) {
          return [];
        }
        ;
        return [aria2("labelledby")(st.titleId)];
      }())(function() {
        var $94 = $$null(st.description);
        if ($94) {
          return [];
        }
        ;
        return [aria2("describedby")(st.descriptionId)];
      }())))(append12([h1(append12([classes2(st.style.title)])(function() {
        var $95 = $$null(st.title);
        if ($95) {
          return [];
        }
        ;
        return [id2(st.titleId)];
      }()))(map25(fromPlainHTML)(st.title)), p(append12([classes2(st.style.description)])(function() {
        var $96 = $$null(st.description);
        if ($96) {
          return [];
        }
        ;
        return [id2(st.descriptionId)];
      }()))(map25(fromPlainHTML)(st.description))])(map25(fromPlainHTML)(st.content)))])])]);
    };
  };
  var render = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([button(append12([type_19(ButtonButton.value), classes2(st.style.trigger), aria2("expanded")(show3(open)), aria2("haspopup")("dialog"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), onClick(function(v) {
      return TriggerClicked.value;
    })])(append12(function() {
      if (open) {
        return [aria2("controls")(st.contentId)];
      }
      ;
      return [];
    }())(portalData(st.triggerAttrs))))(map25(fromPlainHTML)(st.trigger)), overlayContent(open)(st)]);
  };
  var component = function(dictMonadEffect) {
    return mkComponent({
      initialState,
      render,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction(dictMonadEffect),
        handleQuery: handleQuery(dictMonadEffect),
        receive: function($100) {
          return Just.create(Receive2.create($100));
        },
        initialize: new Just(Initialize2.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Behavior.Direction/index.js
  var LTR = /* @__PURE__ */ function() {
    function LTR2() {
    }
    ;
    LTR2.value = new LTR2();
    return LTR2;
  }();
  var RTL = /* @__PURE__ */ function() {
    function RTL2() {
    }
    ;
    RTL2.value = new RTL2();
    return RTL2;
  }();

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Behavior.RovingFocus/index.js
  var eq12 = /* @__PURE__ */ eq(eqOrientation);
  var MoveTo = /* @__PURE__ */ function() {
    function MoveTo2(value0) {
      this.value0 = value0;
    }
    ;
    MoveTo2.create = function(value0) {
      return new MoveTo2(value0);
    };
    return MoveTo2;
  }();
  var Stay = /* @__PURE__ */ function() {
    function Stay2() {
    }
    ;
    Stay2.value = new Stay2();
    return Stay2;
  }();
  var Prev = /* @__PURE__ */ function() {
    function Prev2() {
    }
    ;
    Prev2.value = new Prev2();
    return Prev2;
  }();
  var Next = /* @__PURE__ */ function() {
    function Next2() {
    }
    ;
    Next2.value = new Next2();
    return Next2;
  }();
  var First2 = /* @__PURE__ */ function() {
    function First3() {
    }
    ;
    First3.value = new First3();
    return First3;
  }();
  var Last2 = /* @__PURE__ */ function() {
    function Last3() {
    }
    ;
    Last3.value = new Last3();
    return Last3;
  }();
  var tabIndexFor = function(current2) {
    return function(idx) {
      var $15 = idx === current2;
      if ($15) {
        return 0;
      }
      ;
      return -1 | 0;
    };
  };
  var move = function(loop2) {
    return function(count) {
      return function(current2) {
        return function(v) {
          if (v instanceof First2) {
            return 0;
          }
          ;
          if (v instanceof Last2) {
            return count - 1 | 0;
          }
          ;
          if (v instanceof Prev) {
            var i2 = current2 - 1 | 0;
            var $17 = i2 < 0;
            if ($17) {
              if (loop2) {
                return count - 1 | 0;
              }
              ;
              return 0;
            }
            ;
            return i2;
          }
          ;
          if (v instanceof Next) {
            var i2 = current2 + 1 | 0;
            var $19 = i2 >= count;
            if ($19) {
              if (loop2) {
                return 0;
              }
              ;
              return count - 1 | 0;
            }
            ;
            return i2;
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Radix.Behavior.RovingFocus (line 60, column 27 - line 68, column 65): " + [v.constructor.name]);
        };
      };
    };
  };
  var focusIntent = function(orientation) {
    return function(dir5) {
      return function(key2) {
        var k = function() {
          if (dir5 instanceof RTL && key2 === "ArrowLeft") {
            return "ArrowRight";
          }
          ;
          if (dir5 instanceof RTL && key2 === "ArrowRight") {
            return "ArrowLeft";
          }
          ;
          return key2;
        }();
        if (k === "Home") {
          return new Just(First2.value);
        }
        ;
        if (k === "End") {
          return new Just(Last2.value);
        }
        ;
        if (k === "ArrowUp") {
          var $24 = eq12(orientation)(Vertical.value);
          if ($24) {
            return new Just(Prev.value);
          }
          ;
          return Nothing.value;
        }
        ;
        if (k === "ArrowDown") {
          var $25 = eq12(orientation)(Vertical.value);
          if ($25) {
            return new Just(Next.value);
          }
          ;
          return Nothing.value;
        }
        ;
        if (k === "ArrowLeft") {
          var $26 = eq12(orientation)(Horizontal.value);
          if ($26) {
            return new Just(Prev.value);
          }
          ;
          return Nothing.value;
        }
        ;
        if (k === "ArrowRight") {
          var $27 = eq12(orientation)(Horizontal.value);
          if ($27) {
            return new Just(Next.value);
          }
          ;
          return Nothing.value;
        }
        ;
        return Nothing.value;
      };
    };
  };
  var navigate = function(cfg) {
    return function(st) {
      return function(key2) {
        var v = focusIntent(cfg.orientation)(cfg.dir)(key2);
        if (v instanceof Nothing) {
          return Stay.value;
        }
        ;
        if (v instanceof Just) {
          return new MoveTo(move(cfg.loop)(st.count)(st.current)(v.value0));
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Radix.Behavior.RovingFocus (line 76, column 23 - line 78, column 67): " + [v.constructor.name]);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Float.Compute/index.js
  var max7 = /* @__PURE__ */ max(ordNumber);
  var min5 = /* @__PURE__ */ min(ordNumber);
  var oppositeSide = function(v) {
    if (v instanceof Top) {
      return Bottom.value;
    }
    ;
    if (v instanceof Bottom) {
      return Top.value;
    }
    ;
    if (v instanceof Left2) {
      return Right2.value;
    }
    ;
    if (v instanceof Right2) {
      return Left2.value;
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Radix.Float.Compute (line 59, column 16 - line 63, column 16): " + [v.constructor.name]);
  };
  var insetRect = function(p2) {
    return function(r) {
      return {
        x: r.x + p2,
        y: r.y + p2,
        width: r.width - 2 * p2,
        height: r.height - 2 * p2
      };
    };
  };
  var flipPlacement = function(p2) {
    return {
      align: p2.align,
      side: oppositeSide(p2.side)
    };
  };
  var fits = function(boundary) {
    return function(fl) {
      return function(c) {
        return c.x >= boundary.x && (c.y >= boundary.y && (c.x + fl.width <= boundary.x + boundary.width && c.y + fl.height <= boundary.y + boundary.height));
      };
    };
  };
  var coordsFromPlacement = function(anchor) {
    return function(fl) {
      return function(offset) {
        return function(v) {
          var alignY = function() {
            if (v.align instanceof Start) {
              return anchor.y;
            }
            ;
            if (v.align instanceof Center) {
              return anchor.y + (anchor.height - fl.height) / 2;
            }
            ;
            if (v.align instanceof End) {
              return anchor.y + anchor.height - fl.height;
            }
            ;
            throw new Error("Failed pattern match at Hydrogen.Radix.Float.Compute (line 82, column 12 - line 85, column 48): " + [v.align.constructor.name]);
          }();
          var alignX = function() {
            if (v.align instanceof Start) {
              return anchor.x;
            }
            ;
            if (v.align instanceof Center) {
              return anchor.x + (anchor.width - fl.width) / 2;
            }
            ;
            if (v.align instanceof End) {
              return anchor.x + anchor.width - fl.width;
            }
            ;
            throw new Error("Failed pattern match at Hydrogen.Radix.Float.Compute (line 78, column 12 - line 81, column 46): " + [v.align.constructor.name]);
          }();
          if (v.side instanceof Top) {
            return {
              x: alignX,
              y: anchor.y - fl.height - offset
            };
          }
          ;
          if (v.side instanceof Bottom) {
            return {
              x: alignX,
              y: anchor.y + anchor.height + offset
            };
          }
          ;
          if (v.side instanceof Left2) {
            return {
              x: anchor.x - fl.width - offset,
              y: alignY
            };
          }
          ;
          if (v.side instanceof Right2) {
            return {
              x: anchor.x + anchor.width + offset,
              y: alignY
            };
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Radix.Float.Compute (line 72, column 3 - line 76, column 64): " + [v.side.constructor.name]);
        };
      };
    };
  };
  var flip2 = function(o) {
    var candidates = [o.placement, flipPlacement(o.placement)];
    var boundary = insetRect(o.padding)(o.boundary);
    var ok = function(p2) {
      return fits(boundary)(o.floating)(coordsFromPlacement(o.anchor)(o.floating)(o.offset)(p2));
    };
    return fromMaybe(o.placement)(find2(ok)(candidates));
  };
  var clampN = function(lo) {
    return function(hi) {
      return function(v) {
        return max7(lo)(min5(hi)(v));
      };
    };
  };
  var shift = function(boundary) {
    return function(fl) {
      return function(padding) {
        return function(c) {
          return {
            x: clampN(boundary.x + padding)(boundary.x + boundary.width - fl.width - padding)(c.x),
            y: clampN(boundary.y + padding)(boundary.y + boundary.height - fl.height - padding)(c.y)
          };
        };
      };
    };
  };
  var computePosition = function(o) {
    var placement = flip2(o);
    var c0 = coordsFromPlacement(o.anchor)(o.floating)(o.offset)(placement);
    var c = shift(o.boundary)(o.floating)(o.padding)(c0);
    return {
      x: c.x,
      y: c.y,
      placement
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Float.Popper/index.js
  var show4 = /* @__PURE__ */ show(showNumber);
  var applySecond4 = /* @__PURE__ */ applySecond(applyEffect);
  var max8 = /* @__PURE__ */ max(ordNumber);
  var min6 = /* @__PURE__ */ min(ordNumber);
  var windowTarget = /* @__PURE__ */ map(functorEffect)(toEventTarget2)(windowImpl);
  var viewportRect = function __do10() {
    var win = windowImpl();
    var w = innerWidth(win)();
    var h = innerHeight(win)();
    return {
      x: 0,
      y: 0,
      width: toNumber(w),
      height: toNumber(h)
    };
  };
  var transformOriginFor = function(v) {
    var cross = function() {
      if (v.align instanceof Start) {
        return "0%";
      }
      ;
      if (v.align instanceof Center) {
        return "0px";
      }
      ;
      if (v.align instanceof End) {
        return "100%";
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Float.Popper (line 103, column 13 - line 106, column 20): " + [v.align.constructor.name]);
    }();
    if (v.side instanceof Top) {
      return cross + " 0px";
    }
    ;
    if (v.side instanceof Bottom) {
      return cross + " 0px";
    }
    ;
    if (v.side instanceof Left2) {
      return "0px " + cross;
    }
    ;
    if (v.side instanceof Right2) {
      return "0px " + cross;
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Radix.Float.Popper (line 110, column 5 - line 114, column 31): " + [v.side.constructor.name]);
  };
  var measureRect = function(el2) {
    return function __do12() {
      var r = getBoundingClientRect(toElement(el2))();
      return {
        x: r.x,
        y: r.y,
        width: r.width,
        height: r.height
      };
    };
  };
  var positionArrow = function(p2) {
    return function __do12() {
      var a2 = measureRect(p2.anchor)();
      var fl = measureRect(p2.floating)();
      var ar = measureRect(p2.arrow)();
      var setT = function(v) {
        return setInlineStyle(p2.arrow)("top")(show4(v) + "px");
      };
      var setR = function(d) {
        return setInlineStyle(p2.arrow)("transform")("rotate(" + (show4(d) + "deg)"));
      };
      var setL = function(v) {
        return setInlineStyle(p2.arrow)("left")(show4(v) + "px");
      };
      var place = function(deg) {
        return function(lv) {
          return function(tv) {
            return function(origin3) {
              return applySecond4(applySecond4(applySecond4(applySecond4(setInlineStyle(p2.arrow)("position")("absolute"))(setR(deg)))(setL(lv)))(setT(tv)))(setInlineStyle(p2.arrow)("transform-origin")(origin3));
            };
          };
        };
      };
      var clamp = function(lo) {
        return function(hi) {
          return function(v) {
            return max8(lo)(min6(hi)(v));
          };
        };
      };
      var crossX = clamp(p2.padding)(fl.width - ar.width - p2.padding)(a2.x + a2.width / 2 - fl.x - ar.width / 2);
      var crossY = clamp(p2.padding)(fl.height - ar.height - p2.padding)(a2.y + a2.height / 2 - fl.y - ar.height / 2);
      if (p2.side instanceof Bottom) {
        return place(180)(crossX)(-ar.height)("center 0px")();
      }
      ;
      if (p2.side instanceof Top) {
        return place(0)(crossX)(fl.height)("center 0px")();
      }
      ;
      if (p2.side instanceof Right2) {
        return place(90)(-ar.width)(crossY)("0px center")();
      }
      ;
      if (p2.side instanceof Left2) {
        return place(270)(fl.width)(crossY)("0px center")();
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Float.Popper (line 249, column 3 - line 253, column 53): " + [p2.side.constructor.name]);
    };
  };
  var positionItemAligned = function(p2) {
    return function __do12() {
      var t = measureRect(p2.trigger)();
      var c = measureRect(p2.content)();
      var it = measureRect(p2.selectedItem)();
      var vp = viewportRect();
      var set = setInlineStyle(p2.wrapper);
      var selOffset = it.y - c.y;
      var rawTop = t.y + t.height / 2 - (selOffset + it.height / 2);
      var px = function(n) {
        return show4(n) + "px";
      };
      var maxH = vp.height - 2 * p2.padding;
      var clamp = function(lo) {
        return function(hi) {
          return function(v) {
            return max8(lo)(min6(max8(lo)(hi))(v));
          };
        };
      };
      var left = clamp(vp.x + p2.padding)(vp.x + vp.width - c.width - p2.padding)(t.x);
      var top2 = clamp(vp.y + p2.padding)(vp.y + vp.height - c.height - p2.padding)(rawTop);
      set("display")("flex")();
      set("flex-direction")("column")();
      set("position")("fixed")();
      set("min-width")(px(t.width))();
      set("left")(px(left))();
      set("top")(px(top2))();
      set("height")(px(c.height))();
      set("margin")("10px 0px")();
      set("min-height")("0px")();
      set("max-height")(px(maxH))();
      return set("z-index")("auto")();
    };
  };
  var positionWrapperWith = function(p2) {
    return function __do12() {
      var fl = measureRect(p2.floating)();
      var boundary = viewportRect();
      var solved = computePosition({
        anchor: p2.anchor,
        floating: {
          width: fl.width,
          height: fl.height
        },
        placement: {
          side: p2.side,
          align: p2.align
        },
        offset: p2.offset,
        boundary,
        padding: p2.padding
      });
      var set = setInlineStyle(p2.wrapper);
      var px = function(n) {
        return show4(n) + "px";
      };
      var availW = boundary.width - 2 * p2.padding;
      var availH = boundary.height - 2 * p2.padding;
      set("position")("fixed")();
      set("left")("0px")();
      set("top")("0px")();
      set("transform")("translate(" + (px(solved.x) + (", " + (px(solved.y) + ")"))))();
      set("min-width")("max-content")();
      set("z-index")("auto")();
      set("--radix-popper-available-width")(px(availW))();
      set("--radix-popper-available-height")(px(availH))();
      set("--radix-popper-anchor-width")(px(p2.anchor.width))();
      set("--radix-popper-anchor-height")(px(p2.anchor.height))();
      set("--radix-popper-transform-origin")(transformOriginFor(solved.placement))();
      return solved;
    };
  };
  var positionWrapper = function(p2) {
    return function __do12() {
      var anchor = measureRect(p2.anchor)();
      return positionWrapperWith({
        anchor,
        wrapper: p2.wrapper,
        floating: p2.floating,
        side: p2.side,
        align: p2.align,
        offset: p2.offset,
        padding: p2.padding
      })();
    };
  };
  var positionWrapperAt = function(p2) {
    return positionWrapperWith({
      anchor: {
        x: p2.point.x,
        y: p2.point.y,
        width: 0,
        height: 0
      },
      wrapper: p2.wrapper,
      floating: p2.floating,
      side: p2.side,
      align: p2.align,
      offset: p2.offset,
      padding: p2.padding
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.MouseEvent/foreign.js
  function clientX(e) {
    return e.clientX;
  }
  function clientY(e) {
    return e.clientY;
  }

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Web.UIEvent.MouseEvent/index.js
  var toEvent2 = unsafeCoerce2;
  var fromEvent2 = /* @__PURE__ */ unsafeReadProtoTagged("MouseEvent");

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.ContextMenu/index.js
  var bind10 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight3 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard5 = /* @__PURE__ */ discard(discardUnit);
  var discard13 = /* @__PURE__ */ discard5(bindHalogenM);
  var pure14 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map26 = /* @__PURE__ */ map(functorArray);
  var show5 = /* @__PURE__ */ show(showInt);
  var append13 = /* @__PURE__ */ append(semigroupArray);
  var foldl2 = /* @__PURE__ */ foldl(foldableArray);
  var when7 = /* @__PURE__ */ when(applicativeEffect);
  var for_5 = /* @__PURE__ */ for_(applicativeEffect)(foldableMaybe);
  var get3 = /* @__PURE__ */ get(monadStateHalogenM);
  var when1 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind16 = /* @__PURE__ */ bind(bindEffect);
  var modify_4 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var map112 = /* @__PURE__ */ map(functorHalogenM);
  var map27 = /* @__PURE__ */ map(functorMaybe);
  var notEq2 = /* @__PURE__ */ notEq(eqSide);
  var notEq1 = /* @__PURE__ */ notEq(eqAlign);
  var traverse_9 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableArray);
  var for_12 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var applySecond5 = /* @__PURE__ */ applySecond(applyEffect);
  var SetOpen2 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen2 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged2 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var ItemSelected = /* @__PURE__ */ function() {
    function ItemSelected3(value0) {
      this.value0 = value0;
    }
    ;
    ItemSelected3.create = function(value0) {
      return new ItemSelected3(value0);
    };
    return ItemSelected3;
  }();
  var MenuItemEntry = /* @__PURE__ */ function() {
    function MenuItemEntry3(value0) {
      this.value0 = value0;
    }
    ;
    MenuItemEntry3.create = function(value0) {
      return new MenuItemEntry3(value0);
    };
    return MenuItemEntry3;
  }();
  var MenuSeparator = /* @__PURE__ */ function() {
    function MenuSeparator3() {
    }
    ;
    MenuSeparator3.value = new MenuSeparator3();
    return MenuSeparator3;
  }();
  var Receive3 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var Opened = /* @__PURE__ */ function() {
    function Opened2(value0) {
      this.value0 = value0;
    }
    ;
    Opened2.create = function(value0) {
      return new Opened2(value0);
    };
    return Opened2;
  }();
  var AfterOpen2 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var EscapePressed2 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var PointerDown = /* @__PURE__ */ function() {
    function PointerDown5(value0) {
      this.value0 = value0;
    }
    ;
    PointerDown5.create = function(value0) {
      return new PointerDown5(value0);
    };
    return PointerDown5;
  }();
  var MenuKeyDown = /* @__PURE__ */ function() {
    function MenuKeyDown3(value0) {
      this.value0 = value0;
    }
    ;
    MenuKeyDown3.create = function(value0) {
      return new MenuKeyDown3(value0);
    };
    return MenuKeyDown3;
  }();
  var ItemClicked = /* @__PURE__ */ function() {
    function ItemClicked3(value0) {
      this.value0 = value0;
    }
    ;
    ItemClicked3.create = function(value0) {
      return new ItemClicked3(value0);
    };
    return ItemClicked3;
  }();
  var Reposition = /* @__PURE__ */ function() {
    function Reposition7() {
    }
    ;
    Reposition7.value = new Reposition7();
    return Reposition7;
  }();
  var wrapperRef = "rdx-context-menu-wrapper";
  var triggerRef = "rdx-context-menu-trigger";
  var scheduleAfterOpen2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind10(liftEffect7(create3))(function(v) {
      return bind10(subscribe2(voidRight3(AfterOpen2.value)(v.emitter)))(function(sid) {
        return discard13(liftEffect7(queueMicrotask2(notify(v.listener)(unit))))(function() {
          return pure14(sid);
        });
      });
    });
  };
  var renderSep = function(st) {
    return div3([classes2(st.style.separator), role("separator"), aria("orientation")("horizontal")])([]);
  };
  var portalData2 = /* @__PURE__ */ map26(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var menuSeparator = /* @__PURE__ */ function() {
    return MenuSeparator.value;
  }();
  var itemRef = function(pfx) {
    return function(i2) {
      return pfx + ("-item-" + show5(i2));
    };
  };
  var renderItem = function(st) {
    return function(idx) {
      return function(item) {
        return div3(append13([ref2(itemRef(st.idPrefix)(idx)), role("menuitem"), classes2(st.style.item), tabIndex2(tabIndexFor(st.focused)(idx)), dataAttr("radix-collection-item")(""), dataAttr("orientation")("vertical"), onClick(function(v) {
          return new ItemClicked(item.value);
        })])(append13(function() {
          var $90 = st.focused === idx;
          if ($90) {
            return [dataAttr("highlighted")("")];
          }
          ;
          return [];
        }())(append13(function() {
          var $91 = item.accent === "";
          if ($91) {
            return [];
          }
          ;
          return [dataAttr("accent-color")(item.accent)];
        }())(function() {
          if (item.disabled) {
            return [dataAttr("disabled")(""), aria("disabled")("true")];
          }
          ;
          return [];
        }()))))(append13(map26(fromPlainHTML)(item.label))(function() {
          var $93 = $$null(item.shortcut);
          if ($93) {
            return [];
          }
          ;
          return [div3([classes2(st.style.shortcut)])(map26(fromPlainHTML)(item.shortcut))];
        }()));
      };
    };
  };
  var renderEntries = function(st) {
    var step4 = function(acc) {
      return function(v) {
        if (v instanceof MenuSeparator) {
          return {
            idx: acc.idx,
            html: append13(acc.html)([renderSep(st)])
          };
        }
        ;
        if (v instanceof MenuItemEntry) {
          return {
            idx: acc.idx + 1 | 0,
            html: append13(acc.html)([renderItem(st)(acc.idx)(v.value0)])
          };
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Radix.ContextMenu (line 328, column 14 - line 333, column 8): " + [v.constructor.name]);
      };
    };
    return function(v) {
      return v.html;
    }(foldl2(step4)({
      idx: 0,
      html: []
    })(st.entries));
  };
  var itemCount = /* @__PURE__ */ function() {
    var $144 = filter(function(v) {
      if (v instanceof MenuItemEntry) {
        return true;
      }
      ;
      if (v instanceof MenuSeparator) {
        return false;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.ContextMenu (line 98, column 43 - line 100, column 25): " + [v.constructor.name]);
    });
    return function($145) {
      return length($144($145));
    };
  }();
  var initialState2 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      entries: input3.entries,
      focused: 0,
      side: input3.side,
      align: input3.align,
      offset: input3.offset,
      padding: input3.padding,
      placedSide: input3.side,
      placedAlign: input3.align,
      idPrefix: input3.idPrefix,
      style: input3.style,
      trigger: input3.trigger,
      triggerStyle: input3.triggerStyle,
      contentStyle: input3.contentStyle,
      portalAttrs: input3.portalAttrs,
      restoreEl: Nothing.value,
      subs: [],
      postSub: Nothing.value,
      contentNode: Nothing.value,
      point: {
        x: 0,
        y: 0
      }
    };
  };
  var dir2 = /* @__PURE__ */ attr2("dir");
  var defaultStyle2 = {
    trigger: /* @__PURE__ */ cn("rdx-context-menu-trigger"),
    content: /* @__PURE__ */ cn("rdx-context-menu-content"),
    scrollRoot: /* @__PURE__ */ cn("rdx-context-menu-scroll-root"),
    scrollViewport: /* @__PURE__ */ cn("rdx-context-menu-scroll-viewport"),
    menuViewport: /* @__PURE__ */ cn("rdx-context-menu-viewport"),
    focusRing: /* @__PURE__ */ cn("rdx-context-menu-focus-ring"),
    item: /* @__PURE__ */ cn("rdx-context-menu-item"),
    shortcut: /* @__PURE__ */ cn("rdx-context-menu-shortcut"),
    separator: /* @__PURE__ */ cn("rdx-context-menu-separator")
  };
  var defaultInput2 = /* @__PURE__ */ function() {
    return {
      entries: [],
      open: Nothing.value,
      defaultOpen: false,
      side: Bottom.value,
      align: Start.value,
      offset: 4,
      padding: 8,
      idPrefix: "rdx-context-menu",
      style: defaultStyle2,
      trigger: [],
      triggerStyle: "",
      contentStyle: "",
      portalAttrs: []
    };
  }();
  var contentRef2 = "rdx-context-menu-content";
  var finalize = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return function(focusToo) {
      return bind10(liftEffect7(documentBody))(function(mbody) {
        return bind10(getHTMLElementRef(wrapperRef))(function(mwrap) {
          return bind10(function() {
            if (focusToo) {
              return getHTMLElementRef(contentRef2);
            }
            ;
            return pure14(Nothing.value);
          }())(function(mcontent) {
            if (mbody instanceof Just && mwrap instanceof Just) {
              return liftEffect7(function __do12() {
                adopt(mbody.value0)(toElement(mwrap.value0))();
                return when7(focusToo)(function __do13() {
                  lockScroll();
                  addFocusGuards();
                  hideOthers(mwrap.value0)();
                  return for_5(mcontent)(focus)();
                })();
              });
            }
            ;
            return pure14(unit);
          });
        });
      });
    };
  };
  var openMenu = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen2(dictMonadEffect);
    return bind10(get3)(function(st) {
      return when1(!current(st.ctrl))(bind10(liftEffect7(bind16(windowImpl)(document)))(function(doc) {
        return bind10(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard13(modify_4(function(v) {
            var $103 = {};
            for (var $104 in v) {
              if ({}.hasOwnProperty.call(v, $104)) {
                $103[$104] = v[$104];
              }
              ;
            }
            ;
            $103.ctrl = change2(true)(st.ctrl).next;
            $103.focused = -1 | 0;
            $103.restoreEl = mprev;
            return $103;
          }))(function() {
            return discard13(raise(new OpenChanged2(true)))(function() {
              return bind10(map112(map27(toNode))(getHTMLElementRef(contentRef2)))(function(mcNode) {
                return bind10(liftEffect7(windowTarget))(function(win) {
                  var docTarget = toEventTarget(doc);
                  return bind10(subscribe2($$escape(docTarget)(EscapePressed2.value)))(function(escSub) {
                    return bind10(subscribe2(pointerDown(docTarget)(PointerDown.create)))(function(ptrSub) {
                      return bind10(subscribe2(eventListener2("scroll")(win)(function(v) {
                        return new Just(Reposition.value);
                      })))(function(scrollSub) {
                        return bind10(subscribe2(eventListener2("resize")(win)(function(v) {
                          return new Just(Reposition.value);
                        })))(function(resizeSub) {
                          return bind10(scheduleAfterOpen1)(function(psid) {
                            return modify_4(function(v) {
                              var $106 = {};
                              for (var $107 in v) {
                                if ({}.hasOwnProperty.call(v, $107)) {
                                  $106[$107] = v[$107];
                                }
                                ;
                              }
                              ;
                              $106.contentNode = mcNode;
                              $106.subs = [escSub, ptrSub, scrollSub, resizeSub];
                              $106.postSub = new Just(psid);
                              return $106;
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var render2 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([div3([ref2(triggerRef), classes2(st.style.trigger), style(st.triggerStyle), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), handler2("contextmenu")(Opened.create)])(map26(fromPlainHTML)(st.trigger)), div3([ref2(wrapperRef), dataAttr("radix-popper-content-wrapper")(""), dir2("ltr"), style(function() {
      if (open) {
        return "position: fixed;";
      }
      ;
      return "display:none;";
    }())])([div3(append13([ref2(contentRef2), role("menu"), classes2(st.style.content), aria("orientation")("vertical"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("side")(sideName(st.placedSide)), dataAttr("align")(alignName(st.placedAlign)), dataAttr("orientation")("vertical"), dataAttr("radix-menu-content")(""), dir2("ltr"), tabIndex2(-1 | 0), style(st.contentStyle), onKeyDown(MenuKeyDown.create)])(portalData2(st.portalAttrs)))([div3([classes2(st.style.scrollRoot), dir2("ltr"), style("position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;")])([div3([classes2(st.style.scrollViewport), dataAttr("radix-scroll-area-viewport")(""), style("overflow: scroll;")])([div3([style("min-width: 100%; display: table;")])([div3([classes2(st.style.menuViewport)])(renderEntries(st))])]), div3([classes2(st.style.focusRing)])([])])])])]);
  };
  var reposition = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind10(get3)(function(st) {
      return bind10(getHTMLElementRef(wrapperRef))(function(mwrap) {
        return bind10(getHTMLElementRef(contentRef2))(function(mfloat) {
          if (mwrap instanceof Just && mfloat instanceof Just) {
            return bind10(liftEffect7(positionWrapperAt({
              point: st.point,
              wrapper: mwrap.value0,
              floating: mfloat.value0,
              side: st.side,
              align: st.align,
              offset: st.offset,
              padding: st.padding
            })))(function(placed) {
              return when1(notEq2(placed.placement.side)(st.placedSide) || notEq1(placed.placement.align)(st.placedAlign))(modify_4(function(v) {
                var $114 = {};
                for (var $115 in v) {
                  if ({}.hasOwnProperty.call(v, $115)) {
                    $114[$115] = v[$115];
                  }
                  ;
                }
                ;
                $114.placedSide = placed.placement.side;
                $114.placedAlign = placed.placement.align;
                return $114;
              }));
            });
          }
          ;
          return pure14(unit);
        });
      });
    });
  };
  var closeMenu = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind10(get3)(function(st) {
      return when1(current(st.ctrl))(discard13(traverse_9(unsubscribe2)(st.subs))(function() {
        return discard13(for_12(st.postSub)(unsubscribe2))(function() {
          return discard13(liftEffect7(applySecond5(applySecond5(showOthers)(removeFocusGuards))(unlockScroll)))(function() {
            return discard13(for_12(st.restoreEl)(function($146) {
              return liftEffect7(focus($146));
            }))(function() {
              return discard13(modify_4(function(v) {
                var $119 = {};
                for (var $120 in v) {
                  if ({}.hasOwnProperty.call(v, $120)) {
                    $119[$120] = v[$120];
                  }
                  ;
                }
                ;
                $119.ctrl = change2(false)(st.ctrl).next;
                $119.restoreEl = Nothing.value;
                $119.subs = [];
                $119.postSub = Nothing.value;
                $119.contentNode = Nothing.value;
                return $119;
              }))(function() {
                return raise(new OpenChanged2(false));
              });
            });
          });
        });
      }));
    });
  };
  var handleAction2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var openMenu1 = openMenu(dictMonadEffect);
    var reposition1 = reposition(dictMonadEffect);
    var finalize1 = finalize(dictMonadEffect);
    var closeMenu1 = closeMenu(dictMonadEffect);
    return function(v) {
      if (v instanceof Receive3) {
        return modify_4(function(st) {
          var $123 = {};
          for (var $124 in st) {
            if ({}.hasOwnProperty.call(st, $124)) {
              $123[$124] = st[$124];
            }
            ;
          }
          ;
          $123.ctrl = sync(v.value0.open)(st.ctrl);
          $123.entries = v.value0.entries;
          $123.side = v.value0.side;
          $123.align = v.value0.align;
          $123.offset = v.value0.offset;
          $123.padding = v.value0.padding;
          $123.idPrefix = v.value0.idPrefix;
          $123.style = v.value0.style;
          $123.trigger = v.value0.trigger;
          $123.triggerStyle = v.value0.triggerStyle;
          $123.contentStyle = v.value0.contentStyle;
          $123.portalAttrs = v.value0.portalAttrs;
          return $123;
        });
      }
      ;
      if (v instanceof Opened) {
        return discard13(liftEffect7(preventDefault(v.value0)))(function() {
          return discard13(for_12(fromEvent2(v.value0))(function(me) {
            return modify_4(function(v1) {
              var $127 = {};
              for (var $128 in v1) {
                if ({}.hasOwnProperty.call(v1, $128)) {
                  $127[$128] = v1[$128];
                }
                ;
              }
              ;
              $127.point = {
                x: toNumber(clientX(me)),
                y: toNumber(clientY(me))
              };
              return $127;
            });
          }))(function() {
            return bind10(get3)(function(st) {
              return when1(!current(st.ctrl))(openMenu1);
            });
          });
        });
      }
      ;
      if (v instanceof AfterOpen2) {
        return discard13(reposition1)(function() {
          return finalize1(true);
        });
      }
      ;
      if (v instanceof EscapePressed2) {
        return closeMenu1;
      }
      ;
      if (v instanceof PointerDown) {
        return bind10(get3)(function(st) {
          return for_12(st.contentNode)(function(node) {
            return bind10(liftEffect7(isOutside(node)(v.value0)))(function(outside) {
              return when1(outside)(closeMenu1);
            });
          });
        });
      }
      ;
      if (v instanceof MenuKeyDown) {
        return bind10(get3)(function(st) {
          var pos = {
            count: itemCount(st.entries),
            current: st.focused
          };
          var cfg = {
            orientation: Vertical.value,
            dir: LTR.value,
            loop: true
          };
          var v1 = navigate(cfg)(pos)(key(v.value0));
          if (v1 instanceof Stay) {
            return pure14(unit);
          }
          ;
          if (v1 instanceof MoveTo) {
            return discard13(modify_4(function(v2) {
              var $133 = {};
              for (var $134 in v2) {
                if ({}.hasOwnProperty.call(v2, $134)) {
                  $133[$134] = v2[$134];
                }
                ;
              }
              ;
              $133.focused = v1.value0;
              return $133;
            }))(function() {
              return bind10(getHTMLElementRef(wrapperRef))(function(mwrap) {
                return bind10(getHTMLElementRef(itemRef(st.idPrefix)(v1.value0)))(function(mitem) {
                  return liftEffect7(queueMicrotask2(function __do12() {
                    for_5(mwrap)(reAdoptBeforeTrail)();
                    return for_5(mitem)(focus)();
                  }));
                });
              });
            });
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Radix.ContextMenu (line 406, column 5 - line 416, column 39): " + [v1.constructor.name]);
        });
      }
      ;
      if (v instanceof ItemClicked) {
        return discard13(raise(new ItemSelected(v.value0)))(function() {
          return closeMenu1;
        });
      }
      ;
      if (v instanceof Reposition) {
        return reposition1;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.ContextMenu (line 366, column 16 - line 423, column 27): " + [v.constructor.name]);
    };
  };
  var handleQuery2 = function(dictMonadEffect) {
    var openMenu1 = openMenu(dictMonadEffect);
    var closeMenu1 = closeMenu(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen2) {
        return discard13(function() {
          if (v.value0) {
            return openMenu1;
          }
          ;
          return closeMenu1;
        }())(function() {
          return pure14(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen2) {
        return bind10(get3)(function(st) {
          return pure14(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.ContextMenu (line 514, column 15 - line 520, column 42): " + [v.constructor.name]);
    };
  };
  var component2 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState2,
      render: render2,
      "eval": mkEval({
        initialize: defaultEval.initialize,
        finalize: defaultEval.finalize,
        handleAction: handleAction2(dictMonadEffect),
        handleQuery: handleQuery2(dictMonadEffect),
        receive: function($147) {
          return Just.create(Receive3.create($147));
        }
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Dialog/index.js
  var bind11 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight4 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard6 = /* @__PURE__ */ discard(discardUnit);
  var discard14 = /* @__PURE__ */ discard6(bindHalogenM);
  var pure15 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map28 = /* @__PURE__ */ map(functorArray);
  var get4 = /* @__PURE__ */ get(monadStateHalogenM);
  var when8 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind17 = /* @__PURE__ */ bind(bindEffect);
  var modify_5 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var map113 = /* @__PURE__ */ map(functorHalogenM);
  var for_6 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var applySecond6 = /* @__PURE__ */ applySecond(applyEffect);
  var $$void9 = /* @__PURE__ */ $$void(functorEffect);
  var append14 = /* @__PURE__ */ append(semigroupArray);
  var type_20 = /* @__PURE__ */ type_17(isPropButtonType);
  var show6 = /* @__PURE__ */ show(showBoolean);
  var SetOpen3 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen3 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged3 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var Initialize3 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive4 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var TriggerClicked2 = /* @__PURE__ */ function() {
    function TriggerClicked6() {
    }
    ;
    TriggerClicked6.value = new TriggerClicked6();
    return TriggerClicked6;
  }();
  var OverlayClicked = /* @__PURE__ */ function() {
    function OverlayClicked2(value0) {
      this.value0 = value0;
    }
    ;
    OverlayClicked2.create = function(value0) {
      return new OverlayClicked2(value0);
    };
    return OverlayClicked2;
  }();
  var ContentKeyDown2 = /* @__PURE__ */ function() {
    function ContentKeyDown4(value0) {
      this.value0 = value0;
    }
    ;
    ContentKeyDown4.create = function(value0) {
      return new ContentKeyDown4(value0);
    };
    return ContentKeyDown4;
  }();
  var EscapePressed3 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var AfterOpen3 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var scheduleAfterOpen3 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind11(liftEffect7(create3))(function(v) {
      return bind11(subscribe2(voidRight4(AfterOpen3.value)(v.emitter)))(function(sid) {
        return discard14(liftEffect7(afterFrame(notify(v.listener)(unit))))(function() {
          return pure15(sid);
        });
      });
    });
  };
  var roleAttr2 = /* @__PURE__ */ attr2("role");
  var portalRef2 = "rdx-dialog-portal";
  var portalData3 = /* @__PURE__ */ map28(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var openDialog2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen3(dictMonadEffect);
    return bind11(get4)(function(st) {
      return when8(!current(st.ctrl))(bind11(liftEffect7(bind17(windowImpl)(document)))(function(doc) {
        return bind11(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard14(modify_5(function(v) {
            var $62 = {};
            for (var $63 in v) {
              if ({}.hasOwnProperty.call(v, $63)) {
                $62[$63] = v[$63];
              }
              ;
            }
            ;
            $62.ctrl = change2(true)(st.ctrl).next;
            $62.restoreEl = mprev;
            return $62;
          }))(function() {
            return discard14(raise(new OpenChanged3(true)))(function() {
              return bind11(function() {
                if (st.closeOnEscape) {
                  return map113(Just.create)(subscribe2($$escape(toEventTarget(doc))(EscapePressed3.value)));
                }
                ;
                return pure15(Nothing.value);
              }())(function(sub3) {
                return bind11(scheduleAfterOpen1)(function(psid) {
                  return modify_5(function(v) {
                    var $66 = {};
                    for (var $67 in v) {
                      if ({}.hasOwnProperty.call(v, $67)) {
                        $66[$67] = v[$67];
                      }
                      ;
                    }
                    ;
                    $66.escSub = sub3;
                    $66.postSub = new Just(psid);
                    $66.locked = st.modal;
                    return $66;
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var initialState3 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      modal: input3.modal,
      closeOnEscape: input3.closeOnEscape,
      closeOnOutsideClick: input3.closeOnOutsideClick,
      style: input3.style,
      trigger: input3.trigger,
      title: input3.title,
      description: input3.description,
      content: input3.content,
      contentStyle: input3.contentStyle,
      triggerAttrs: input3.triggerAttrs,
      portalAttrs: input3.portalAttrs,
      restoreEl: Nothing.value,
      escSub: Nothing.value,
      postSub: Nothing.value,
      locked: false,
      contentId: "",
      titleId: "",
      descriptionId: ""
    };
  };
  var defaultStyle3 = {
    trigger: /* @__PURE__ */ cn("rdx-dialog-trigger"),
    overlay: /* @__PURE__ */ cn("rdx-dialog-overlay"),
    scroll: /* @__PURE__ */ cn("rdx-dialog-scroll"),
    scrollPadding: /* @__PURE__ */ cn("rdx-dialog-scroll-padding"),
    content: /* @__PURE__ */ cn("rdx-dialog-content"),
    title: /* @__PURE__ */ cn("rdx-dialog-title"),
    description: /* @__PURE__ */ cn("rdx-dialog-description")
  };
  var defaultInput3 = /* @__PURE__ */ function() {
    return {
      open: Nothing.value,
      defaultOpen: false,
      modal: true,
      closeOnEscape: true,
      closeOnOutsideClick: true,
      style: defaultStyle3,
      trigger: [],
      title: [],
      description: [],
      content: [],
      contentStyle: "",
      triggerAttrs: [],
      portalAttrs: []
    };
  }();
  var contentRef3 = "rdx-dialog-content";
  var closeDialog2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind11(get4)(function(st) {
      return when8(current(st.ctrl))(discard14(for_6(st.escSub)(unsubscribe2))(function() {
        return discard14(for_6(st.postSub)(unsubscribe2))(function() {
          return discard14(for_6(st.restoreEl)(function($100) {
            return liftEffect7(focus($100));
          }))(function() {
            return discard14(when8(st.locked)(liftEffect7(applySecond6(applySecond6(showOthers)(removeFocusGuards))(unlockScroll))))(function() {
              return discard14(modify_5(function(v) {
                var $69 = {};
                for (var $70 in v) {
                  if ({}.hasOwnProperty.call(v, $70)) {
                    $69[$70] = v[$70];
                  }
                  ;
                }
                ;
                $69.ctrl = change2(false)(st.ctrl).next;
                $69.restoreEl = Nothing.value;
                $69.escSub = Nothing.value;
                $69.postSub = Nothing.value;
                $69.locked = false;
                return $69;
              }))(function() {
                return raise(new OpenChanged3(false));
              });
            });
          });
        });
      }));
    });
  };
  var handleAction3 = function(dictMonadEffect) {
    var monadEffectHalogenM2 = monadEffectHalogenM(dictMonadEffect);
    var useId2 = useId(monadEffectHalogenM2);
    var openDialog1 = openDialog2(dictMonadEffect);
    var liftEffect7 = liftEffect(monadEffectHalogenM2);
    var closeDialog1 = closeDialog2(dictMonadEffect);
    return function(v) {
      if (v instanceof Initialize3) {
        return bind11(useId2)(function(cid) {
          return bind11(useId2)(function(tid) {
            return bind11(useId2)(function(did) {
              return modify_5(function(v1) {
                var $73 = {};
                for (var $74 in v1) {
                  if ({}.hasOwnProperty.call(v1, $74)) {
                    $73[$74] = v1[$74];
                  }
                  ;
                }
                ;
                $73.contentId = cid;
                $73.titleId = tid;
                $73.descriptionId = did;
                return $73;
              });
            });
          });
        });
      }
      ;
      if (v instanceof Receive4) {
        return modify_5(function(st) {
          var $76 = {};
          for (var $77 in st) {
            if ({}.hasOwnProperty.call(st, $77)) {
              $76[$77] = st[$77];
            }
            ;
          }
          ;
          $76.ctrl = sync(v.value0.open)(st.ctrl);
          $76.modal = v.value0.modal;
          $76.closeOnEscape = v.value0.closeOnEscape;
          $76.closeOnOutsideClick = v.value0.closeOnOutsideClick;
          $76.style = v.value0.style;
          $76.trigger = v.value0.trigger;
          $76.title = v.value0.title;
          $76.description = v.value0.description;
          $76.content = v.value0.content;
          $76.contentStyle = v.value0.contentStyle;
          $76.triggerAttrs = v.value0.triggerAttrs;
          $76.portalAttrs = v.value0.portalAttrs;
          return $76;
        });
      }
      ;
      if (v instanceof TriggerClicked2) {
        return openDialog1;
      }
      ;
      if (v instanceof OverlayClicked) {
        return bind11(get4)(function(st) {
          return when8(st.closeOnOutsideClick)(bind11(getHTMLElementRef(contentRef3))(function(mc) {
            return for_6(mc)(function(content3) {
              return bind11(liftEffect7(isOutside(toNode(content3))(toEvent2(v.value0))))(function(outside) {
                return when8(outside)(closeDialog1);
              });
            });
          }));
        });
      }
      ;
      if (v instanceof EscapePressed3) {
        return bind11(get4)(function(st) {
          return when8(st.closeOnEscape)(closeDialog1);
        });
      }
      ;
      if (v instanceof ContentKeyDown2) {
        return bind11(getHTMLElementRef(contentRef3))(function(mnode) {
          return for_6(mnode)(function(node) {
            return bind11(liftEffect7(tabLoop(true)(node)(v.value0)))(function(handled) {
              return when8(handled)(liftEffect7(preventDefault(toEvent(v.value0))));
            });
          });
        });
      }
      ;
      if (v instanceof AfterOpen3) {
        return bind11(liftEffect7(documentBody))(function(mbody) {
          return bind11(getHTMLElementRef(portalRef2))(function(mwrap) {
            return discard14(function() {
              if (mbody instanceof Just && mwrap instanceof Just) {
                return liftEffect7(adopt(mbody.value0)(toElement(mwrap.value0)));
              }
              ;
              return pure15(unit);
            }())(function() {
              return bind11(getHTMLElementRef(contentRef3))(function(mnode) {
                return discard14(for_6(mnode)(function(node) {
                  return liftEffect7($$void9(captureFocus(node)));
                }))(function() {
                  return bind11(get4)(function(st) {
                    return when8(st.modal)(for_6(mwrap)(function(wrap3) {
                      return liftEffect7(function __do12() {
                        lockScroll();
                        addFocusGuards();
                        return hideOthers(wrap3)();
                      });
                    }));
                  });
                });
              });
            });
          });
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Dialog (line 288, column 16 - line 346, column 31): " + [v.constructor.name]);
    };
  };
  var handleQuery3 = function(dictMonadEffect) {
    var openDialog1 = openDialog2(dictMonadEffect);
    var closeDialog1 = closeDialog2(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen3) {
        return discard14(function() {
          if (v.value0) {
            return openDialog1;
          }
          ;
          return closeDialog1;
        }())(function() {
          return pure15(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen3) {
        return bind11(get4)(function(st) {
          return pure15(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Dialog (line 387, column 15 - line 393, column 42): " + [v.constructor.name]);
    };
  };
  var aria3 = function(name15) {
    return function(val) {
      return attr2("aria-" + name15)(val);
    };
  };
  var overlayContent2 = function(open) {
    return function(st) {
      return div3(append14([ref2(portalRef2), classes2(st.style.overlay), dataState(function() {
        if (open) {
          return "open";
        }
        ;
        return "closed";
      }()), style(function() {
        if (open) {
          return "pointer-events: auto;";
        }
        ;
        return "display:none;";
      }()), onClick(OverlayClicked.create)])(portalData3(st.portalAttrs)))([div3([classes2(st.style.scroll)])([div3([classes2(st.style.scrollPadding)])([div3(append14([ref2(contentRef3), id2(st.contentId), classes2(st.style.content), roleAttr2("dialog"), dataState(function() {
        if (open) {
          return "open";
        }
        ;
        return "closed";
      }()), tabIndex2(-1 | 0), style(st.contentStyle), onKeyDown(ContentKeyDown2.create)])(append14(function() {
        var $94 = $$null(st.title);
        if ($94) {
          return [];
        }
        ;
        return [aria3("labelledby")(st.titleId)];
      }())(function() {
        var $95 = $$null(st.description);
        if ($95) {
          return [];
        }
        ;
        return [aria3("describedby")(st.descriptionId)];
      }())))(append14([h1(append14([classes2(st.style.title)])(function() {
        var $96 = $$null(st.title);
        if ($96) {
          return [];
        }
        ;
        return [id2(st.titleId)];
      }()))(map28(fromPlainHTML)(st.title)), p(append14([classes2(st.style.description)])(function() {
        var $97 = $$null(st.description);
        if ($97) {
          return [];
        }
        ;
        return [id2(st.descriptionId)];
      }()))(map28(fromPlainHTML)(st.description))])(map28(fromPlainHTML)(st.content)))])])]);
    };
  };
  var render3 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([button(append14([type_20(ButtonButton.value), classes2(st.style.trigger), aria3("expanded")(show6(open)), aria3("haspopup")("dialog"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), onClick(function(v) {
      return TriggerClicked2.value;
    })])(append14(function() {
      if (open) {
        return [aria3("controls")(st.contentId)];
      }
      ;
      return [];
    }())(portalData3(st.triggerAttrs))))(map28(fromPlainHTML)(st.trigger)), overlayContent2(open)(st)]);
  };
  var component3 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState3,
      render: render3,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction3(dictMonadEffect),
        handleQuery: handleQuery3(dictMonadEffect),
        receive: function($101) {
          return Just.create(Receive4.create($101));
        },
        initialize: new Just(Initialize3.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.DropdownMenu/index.js
  var bind18 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight5 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard7 = /* @__PURE__ */ discard(discardUnit);
  var discard15 = /* @__PURE__ */ discard7(bindHalogenM);
  var pure16 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map29 = /* @__PURE__ */ map(functorArray);
  var show7 = /* @__PURE__ */ show(showInt);
  var append15 = /* @__PURE__ */ append(semigroupArray);
  var foldl3 = /* @__PURE__ */ foldl(foldableArray);
  var when9 = /* @__PURE__ */ when(applicativeEffect);
  var for_7 = /* @__PURE__ */ for_(applicativeEffect)(foldableMaybe);
  var get5 = /* @__PURE__ */ get(monadStateHalogenM);
  var when12 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind19 = /* @__PURE__ */ bind(bindEffect);
  var modify_6 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var map114 = /* @__PURE__ */ map(functorHalogenM);
  var map210 = /* @__PURE__ */ map(functorMaybe);
  var type_21 = /* @__PURE__ */ type_17(isPropButtonType);
  var notEq3 = /* @__PURE__ */ notEq(eqSide);
  var notEq12 = /* @__PURE__ */ notEq(eqAlign);
  var traverse_10 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableArray);
  var for_13 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var applySecond7 = /* @__PURE__ */ applySecond(applyEffect);
  var SetOpen4 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen4 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged4 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var ItemSelected2 = /* @__PURE__ */ function() {
    function ItemSelected3(value0) {
      this.value0 = value0;
    }
    ;
    ItemSelected3.create = function(value0) {
      return new ItemSelected3(value0);
    };
    return ItemSelected3;
  }();
  var MenuItemEntry2 = /* @__PURE__ */ function() {
    function MenuItemEntry3(value0) {
      this.value0 = value0;
    }
    ;
    MenuItemEntry3.create = function(value0) {
      return new MenuItemEntry3(value0);
    };
    return MenuItemEntry3;
  }();
  var MenuSeparator2 = /* @__PURE__ */ function() {
    function MenuSeparator3() {
    }
    ;
    MenuSeparator3.value = new MenuSeparator3();
    return MenuSeparator3;
  }();
  var Initialize4 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive5 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var TriggerClicked3 = /* @__PURE__ */ function() {
    function TriggerClicked6() {
    }
    ;
    TriggerClicked6.value = new TriggerClicked6();
    return TriggerClicked6;
  }();
  var AfterOpen4 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var EscapePressed4 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var PointerDown2 = /* @__PURE__ */ function() {
    function PointerDown5(value0) {
      this.value0 = value0;
    }
    ;
    PointerDown5.create = function(value0) {
      return new PointerDown5(value0);
    };
    return PointerDown5;
  }();
  var MenuKeyDown2 = /* @__PURE__ */ function() {
    function MenuKeyDown3(value0) {
      this.value0 = value0;
    }
    ;
    MenuKeyDown3.create = function(value0) {
      return new MenuKeyDown3(value0);
    };
    return MenuKeyDown3;
  }();
  var ItemClicked2 = /* @__PURE__ */ function() {
    function ItemClicked3(value0) {
      this.value0 = value0;
    }
    ;
    ItemClicked3.create = function(value0) {
      return new ItemClicked3(value0);
    };
    return ItemClicked3;
  }();
  var Reposition2 = /* @__PURE__ */ function() {
    function Reposition7() {
    }
    ;
    Reposition7.value = new Reposition7();
    return Reposition7;
  }();
  var wrapperRef2 = "rdx-dropdown-wrapper";
  var triggerRef2 = "rdx-dropdown-trigger";
  var scheduleAfterOpen4 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind18(liftEffect7(create3))(function(v) {
      return bind18(subscribe2(voidRight5(AfterOpen4.value)(v.emitter)))(function(sid) {
        return discard15(liftEffect7(queueMicrotask2(notify(v.listener)(unit))))(function() {
          return pure16(sid);
        });
      });
    });
  };
  var renderSep2 = function(st) {
    return div3([classes2(st.style.separator), role("separator"), aria("orientation")("horizontal")])([]);
  };
  var portalData4 = /* @__PURE__ */ map29(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var menuSeparator2 = /* @__PURE__ */ function() {
    return MenuSeparator2.value;
  }();
  var itemRef2 = function(pfx) {
    return function(i2) {
      return pfx + ("-item-" + show7(i2));
    };
  };
  var renderItem2 = function(st) {
    return function(idx) {
      return function(item) {
        return div3(append15([ref2(itemRef2(st.idPrefix)(idx)), role("menuitem"), classes2(st.style.item), tabIndex2(tabIndexFor(st.focused)(idx)), dataAttr("radix-collection-item")(""), dataAttr("orientation")("vertical"), onClick(function(v) {
          return new ItemClicked2(item.value);
        })])(append15(function() {
          var $93 = st.focused === idx;
          if ($93) {
            return [dataAttr("highlighted")("")];
          }
          ;
          return [];
        }())(append15(function() {
          var $94 = item.accent === "";
          if ($94) {
            return [];
          }
          ;
          return [dataAttr("accent-color")(item.accent)];
        }())(function() {
          if (item.disabled) {
            return [dataAttr("disabled")(""), aria("disabled")("true")];
          }
          ;
          return [];
        }()))))(append15(map29(fromPlainHTML)(item.label))(function() {
          var $96 = $$null(item.shortcut);
          if ($96) {
            return [];
          }
          ;
          return [div3([classes2(st.style.shortcut)])(map29(fromPlainHTML)(item.shortcut))];
        }()));
      };
    };
  };
  var renderEntries2 = function(st) {
    var step4 = function(acc) {
      return function(v) {
        if (v instanceof MenuSeparator2) {
          return {
            idx: acc.idx,
            html: append15(acc.html)([renderSep2(st)])
          };
        }
        ;
        if (v instanceof MenuItemEntry2) {
          return {
            idx: acc.idx + 1 | 0,
            html: append15(acc.html)([renderItem2(st)(acc.idx)(v.value0)])
          };
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Radix.DropdownMenu (line 340, column 14 - line 345, column 8): " + [v.constructor.name]);
      };
    };
    return function(v) {
      return v.html;
    }(foldl3(step4)({
      idx: 0,
      html: []
    })(st.entries));
  };
  var itemCount2 = /* @__PURE__ */ function() {
    var $151 = filter(function(v) {
      if (v instanceof MenuItemEntry2) {
        return true;
      }
      ;
      if (v instanceof MenuSeparator2) {
        return false;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.DropdownMenu (line 98, column 43 - line 100, column 25): " + [v.constructor.name]);
    });
    return function($152) {
      return length($151($152));
    };
  }();
  var initialState4 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      entries: input3.entries,
      focused: 0,
      side: input3.side,
      align: input3.align,
      offset: input3.offset,
      padding: input3.padding,
      placedSide: input3.side,
      placedAlign: input3.align,
      idPrefix: input3.idPrefix,
      style: input3.style,
      trigger: input3.trigger,
      contentStyle: input3.contentStyle,
      triggerAttrs: input3.triggerAttrs,
      portalAttrs: input3.portalAttrs,
      restoreEl: Nothing.value,
      subs: [],
      postSub: Nothing.value,
      contentNode: Nothing.value,
      triggerId: "",
      contentId: ""
    };
  };
  var dir3 = /* @__PURE__ */ attr2("dir");
  var defaultStyle4 = {
    trigger: /* @__PURE__ */ cn("rdx-dropdown-trigger"),
    content: /* @__PURE__ */ cn("rdx-dropdown-content"),
    scrollRoot: /* @__PURE__ */ cn("rdx-dropdown-scroll-root"),
    scrollViewport: /* @__PURE__ */ cn("rdx-dropdown-scroll-viewport"),
    menuViewport: /* @__PURE__ */ cn("rdx-dropdown-viewport"),
    focusRing: /* @__PURE__ */ cn("rdx-dropdown-focus-ring"),
    item: /* @__PURE__ */ cn("rdx-dropdown-item"),
    shortcut: /* @__PURE__ */ cn("rdx-dropdown-shortcut"),
    separator: /* @__PURE__ */ cn("rdx-dropdown-separator")
  };
  var defaultInput4 = /* @__PURE__ */ function() {
    return {
      entries: [],
      open: Nothing.value,
      defaultOpen: false,
      side: Bottom.value,
      align: Start.value,
      offset: 4,
      padding: 8,
      idPrefix: "rdx-dropdown",
      style: defaultStyle4,
      trigger: [],
      contentStyle: "",
      triggerAttrs: [],
      portalAttrs: []
    };
  }();
  var contentRef4 = "rdx-dropdown-content";
  var finalize2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return function(focusToo) {
      return bind18(liftEffect7(documentBody))(function(mbody) {
        return bind18(getHTMLElementRef(wrapperRef2))(function(mwrap) {
          return bind18(function() {
            if (focusToo) {
              return getHTMLElementRef(contentRef4);
            }
            ;
            return pure16(Nothing.value);
          }())(function(mcontent) {
            if (mbody instanceof Just && mwrap instanceof Just) {
              return liftEffect7(function __do12() {
                adopt(mbody.value0)(toElement(mwrap.value0))();
                return when9(focusToo)(function __do13() {
                  lockScroll();
                  addFocusGuards();
                  hideOthers(mwrap.value0)();
                  return for_7(mcontent)(focus)();
                })();
              });
            }
            ;
            return pure16(unit);
          });
        });
      });
    };
  };
  var openMenu2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen4(dictMonadEffect);
    return bind18(get5)(function(st) {
      return when12(!current(st.ctrl))(bind18(liftEffect7(bind19(windowImpl)(document)))(function(doc) {
        return bind18(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard15(modify_6(function(v) {
            var $106 = {};
            for (var $107 in v) {
              if ({}.hasOwnProperty.call(v, $107)) {
                $106[$107] = v[$107];
              }
              ;
            }
            ;
            $106.ctrl = change2(true)(st.ctrl).next;
            $106.focused = -1 | 0;
            $106.restoreEl = mprev;
            return $106;
          }))(function() {
            return discard15(raise(new OpenChanged4(true)))(function() {
              return bind18(map114(map210(toNode))(getHTMLElementRef(contentRef4)))(function(mcNode) {
                return bind18(liftEffect7(windowTarget))(function(win) {
                  var docTarget = toEventTarget(doc);
                  return bind18(subscribe2($$escape(docTarget)(EscapePressed4.value)))(function(escSub) {
                    return bind18(subscribe2(pointerDown(docTarget)(PointerDown2.create)))(function(ptrSub) {
                      return bind18(subscribe2(eventListener2("scroll")(win)(function(v) {
                        return new Just(Reposition2.value);
                      })))(function(scrollSub) {
                        return bind18(subscribe2(eventListener2("resize")(win)(function(v) {
                          return new Just(Reposition2.value);
                        })))(function(resizeSub) {
                          return bind18(scheduleAfterOpen1)(function(psid) {
                            return modify_6(function(v) {
                              var $109 = {};
                              for (var $110 in v) {
                                if ({}.hasOwnProperty.call(v, $110)) {
                                  $109[$110] = v[$110];
                                }
                                ;
                              }
                              ;
                              $109.contentNode = mcNode;
                              $109.subs = [escSub, ptrSub, scrollSub, resizeSub];
                              $109.postSub = new Just(psid);
                              return $109;
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var render4 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([button(append15([type_21(ButtonButton.value), ref2(triggerRef2), id2(st.triggerId), classes2(st.style.trigger), aria("expanded")(function() {
      if (open) {
        return "true";
      }
      ;
      return "false";
    }()), aria("haspopup")("menu"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("radix-popper-side")(sideName(st.placedSide)), dataAttr("radix-popper-align")(alignName(st.placedAlign)), onClick(function(v) {
      return TriggerClicked3.value;
    })])(append15(function() {
      if (open) {
        return [aria("controls")(st.contentId)];
      }
      ;
      return [];
    }())(portalData4(st.triggerAttrs))))(map29(fromPlainHTML)(st.trigger)), div3([ref2(wrapperRef2), dataAttr("radix-popper-content-wrapper")(""), dir3("ltr"), style(function() {
      if (open) {
        return "position: fixed;";
      }
      ;
      return "display:none;";
    }())])([div3(append15([ref2(contentRef4), id2(st.contentId), role("menu"), classes2(st.style.content), aria("labelledby")(st.triggerId), aria("orientation")("vertical"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("side")(sideName(st.placedSide)), dataAttr("align")(alignName(st.placedAlign)), dataAttr("orientation")("vertical"), dataAttr("radix-menu-content")(""), dir3("ltr"), tabIndex2(-1 | 0), style(st.contentStyle), onKeyDown(MenuKeyDown2.create)])(portalData4(st.portalAttrs)))([div3([classes2(st.style.scrollRoot), dir3("ltr"), style("position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;")])([div3([classes2(st.style.scrollViewport), dataAttr("radix-scroll-area-viewport")(""), style("overflow: scroll;")])([div3([style("min-width: 100%; display: table;")])([div3([classes2(st.style.menuViewport)])(renderEntries2(st))])]), div3([classes2(st.style.focusRing)])([])])])])]);
  };
  var reposition2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind18(get5)(function(st) {
      return bind18(getHTMLElementRef(triggerRef2))(function(manchor) {
        return bind18(getHTMLElementRef(wrapperRef2))(function(mwrap) {
          return bind18(getHTMLElementRef(contentRef4))(function(mfloat) {
            if (manchor instanceof Just && (mwrap instanceof Just && mfloat instanceof Just)) {
              return bind18(liftEffect7(positionWrapper({
                anchor: manchor.value0,
                wrapper: mwrap.value0,
                floating: mfloat.value0,
                side: st.side,
                align: st.align,
                offset: st.offset,
                padding: st.padding
              })))(function(placed) {
                return when12(notEq3(placed.placement.side)(st.placedSide) || notEq12(placed.placement.align)(st.placedAlign))(modify_6(function(v) {
                  var $120 = {};
                  for (var $121 in v) {
                    if ({}.hasOwnProperty.call(v, $121)) {
                      $120[$121] = v[$121];
                    }
                    ;
                  }
                  ;
                  $120.placedSide = placed.placement.side;
                  $120.placedAlign = placed.placement.align;
                  return $120;
                }));
              });
            }
            ;
            return pure16(unit);
          });
        });
      });
    });
  };
  var closeMenu2 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind18(get5)(function(st) {
      return when12(current(st.ctrl))(discard15(traverse_10(unsubscribe2)(st.subs))(function() {
        return discard15(for_13(st.postSub)(unsubscribe2))(function() {
          return discard15(liftEffect7(applySecond7(applySecond7(showOthers)(removeFocusGuards))(unlockScroll)))(function() {
            return discard15(for_13(st.restoreEl)(function($153) {
              return liftEffect7(focus($153));
            }))(function() {
              return discard15(modify_6(function(v) {
                var $126 = {};
                for (var $127 in v) {
                  if ({}.hasOwnProperty.call(v, $127)) {
                    $126[$127] = v[$127];
                  }
                  ;
                }
                ;
                $126.ctrl = change2(false)(st.ctrl).next;
                $126.restoreEl = Nothing.value;
                $126.subs = [];
                $126.postSub = Nothing.value;
                $126.contentNode = Nothing.value;
                return $126;
              }))(function() {
                return raise(new OpenChanged4(false));
              });
            });
          });
        });
      }));
    });
  };
  var handleAction4 = function(dictMonadEffect) {
    var monadEffectHalogenM2 = monadEffectHalogenM(dictMonadEffect);
    var useId2 = useId(monadEffectHalogenM2);
    var closeMenu1 = closeMenu2(dictMonadEffect);
    var openMenu1 = openMenu2(dictMonadEffect);
    var reposition1 = reposition2(dictMonadEffect);
    var finalize1 = finalize2(dictMonadEffect);
    var liftEffect7 = liftEffect(monadEffectHalogenM2);
    return function(v) {
      if (v instanceof Initialize4) {
        return bind18(useId2)(function(tid) {
          return bind18(useId2)(function(cid) {
            return modify_6(function(v1) {
              var $130 = {};
              for (var $131 in v1) {
                if ({}.hasOwnProperty.call(v1, $131)) {
                  $130[$131] = v1[$131];
                }
                ;
              }
              ;
              $130.triggerId = tid;
              $130.contentId = cid;
              return $130;
            });
          });
        });
      }
      ;
      if (v instanceof Receive5) {
        return modify_6(function(st) {
          var $133 = {};
          for (var $134 in st) {
            if ({}.hasOwnProperty.call(st, $134)) {
              $133[$134] = st[$134];
            }
            ;
          }
          ;
          $133.ctrl = sync(v.value0.open)(st.ctrl);
          $133.entries = v.value0.entries;
          $133.side = v.value0.side;
          $133.align = v.value0.align;
          $133.offset = v.value0.offset;
          $133.padding = v.value0.padding;
          $133.idPrefix = v.value0.idPrefix;
          $133.style = v.value0.style;
          $133.trigger = v.value0.trigger;
          $133.contentStyle = v.value0.contentStyle;
          $133.triggerAttrs = v.value0.triggerAttrs;
          $133.portalAttrs = v.value0.portalAttrs;
          return $133;
        });
      }
      ;
      if (v instanceof TriggerClicked3) {
        return bind18(get5)(function(st) {
          var $137 = current(st.ctrl);
          if ($137) {
            return closeMenu1;
          }
          ;
          return openMenu1;
        });
      }
      ;
      if (v instanceof AfterOpen4) {
        return discard15(reposition1)(function() {
          return finalize1(true);
        });
      }
      ;
      if (v instanceof EscapePressed4) {
        return closeMenu1;
      }
      ;
      if (v instanceof PointerDown2) {
        return bind18(get5)(function(st) {
          return for_13(st.contentNode)(function(node) {
            return bind18(liftEffect7(isOutside(node)(v.value0)))(function(outside) {
              return when12(outside)(closeMenu1);
            });
          });
        });
      }
      ;
      if (v instanceof MenuKeyDown2) {
        return bind18(get5)(function(st) {
          var pos = {
            count: itemCount2(st.entries),
            current: st.focused
          };
          var cfg = {
            orientation: Vertical.value,
            dir: LTR.value,
            loop: true
          };
          var v1 = navigate(cfg)(pos)(key(v.value0));
          if (v1 instanceof Stay) {
            return pure16(unit);
          }
          ;
          if (v1 instanceof MoveTo) {
            return discard15(modify_6(function(v2) {
              var $140 = {};
              for (var $141 in v2) {
                if ({}.hasOwnProperty.call(v2, $141)) {
                  $140[$141] = v2[$141];
                }
                ;
              }
              ;
              $140.focused = v1.value0;
              return $140;
            }))(function() {
              return bind18(getHTMLElementRef(wrapperRef2))(function(mwrap) {
                return bind18(getHTMLElementRef(itemRef2(st.idPrefix)(v1.value0)))(function(mitem) {
                  return liftEffect7(queueMicrotask2(function __do12() {
                    for_7(mwrap)(reAdoptBeforeTrail)();
                    return for_7(mitem)(focus)();
                  }));
                });
              });
            });
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Radix.DropdownMenu (line 418, column 5 - line 428, column 39): " + [v1.constructor.name]);
        });
      }
      ;
      if (v instanceof ItemClicked2) {
        return discard15(raise(new ItemSelected2(v.value0)))(function() {
          return closeMenu1;
        });
      }
      ;
      if (v instanceof Reposition2) {
        return reposition1;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.DropdownMenu (line 378, column 16 - line 435, column 27): " + [v.constructor.name]);
    };
  };
  var handleQuery4 = function(dictMonadEffect) {
    var openMenu1 = openMenu2(dictMonadEffect);
    var closeMenu1 = closeMenu2(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen4) {
        return discard15(function() {
          if (v.value0) {
            return openMenu1;
          }
          ;
          return closeMenu1;
        }())(function() {
          return pure16(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen4) {
        return bind18(get5)(function(st) {
          return pure16(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.DropdownMenu (line 527, column 15 - line 533, column 42): " + [v.constructor.name]);
    };
  };
  var component4 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState4,
      render: render4,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction4(dictMonadEffect),
        handleQuery: handleQuery4(dictMonadEffect),
        receive: function($154) {
          return Just.create(Receive5.create($154));
        },
        initialize: new Just(Initialize4.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.HoverCard/index.js
  var bind20 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight6 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard8 = /* @__PURE__ */ discard(discardUnit)(bindHalogenM);
  var pure17 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map30 = /* @__PURE__ */ map(functorArray);
  var get6 = /* @__PURE__ */ get(monadStateHalogenM);
  var when10 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind110 = /* @__PURE__ */ bind(bindEffect);
  var modify_7 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var append16 = /* @__PURE__ */ append(semigroupArray);
  var traverse_11 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableArray);
  var for_8 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var SetOpen5 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen5 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged5 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var Initialize5 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive6 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var Show = /* @__PURE__ */ function() {
    function Show3() {
    }
    ;
    Show3.value = new Show3();
    return Show3;
  }();
  var Hide = /* @__PURE__ */ function() {
    function Hide3() {
    }
    ;
    Hide3.value = new Hide3();
    return Hide3;
  }();
  var AfterOpen5 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var EscapePressed5 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var Reposition3 = /* @__PURE__ */ function() {
    function Reposition7() {
    }
    ;
    Reposition7.value = new Reposition7();
    return Reposition7;
  }();
  var wrapperRef3 = "rdx-hover-card-wrapper";
  var triggerRef3 = "rdx-hover-card-trigger";
  var scheduleAfterOpen5 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind20(liftEffect7(create3))(function(v) {
      return bind20(subscribe2(voidRight6(AfterOpen5.value)(v.emitter)))(function(sid) {
        return discard8(liftEffect7(afterFrame(notify(v.listener)(unit))))(function() {
          return pure17(sid);
        });
      });
    });
  };
  var portalData5 = /* @__PURE__ */ map30(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var openCard = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen5(dictMonadEffect);
    return bind20(get6)(function(st) {
      return when10(!current(st.ctrl))(bind20(liftEffect7(bind110(windowImpl)(document)))(function(doc) {
        return bind20(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard8(modify_7(function(v) {
            var $73 = {};
            for (var $74 in v) {
              if ({}.hasOwnProperty.call(v, $74)) {
                $73[$74] = v[$74];
              }
              ;
            }
            ;
            $73.ctrl = change2(true)(st.ctrl).next;
            $73.restoreEl = mprev;
            return $73;
          }))(function() {
            return discard8(raise(new OpenChanged5(true)))(function() {
              return bind20(liftEffect7(windowTarget))(function(win) {
                var docTarget = toEventTarget(doc);
                return bind20(subscribe2($$escape(docTarget)(EscapePressed5.value)))(function(escSub) {
                  return bind20(subscribe2(eventListener2("scroll")(win)(function(v) {
                    return new Just(Reposition3.value);
                  })))(function(scrollSub) {
                    return bind20(subscribe2(eventListener2("resize")(win)(function(v) {
                      return new Just(Reposition3.value);
                    })))(function(resizeSub) {
                      return bind20(scheduleAfterOpen1)(function(psid) {
                        return modify_7(function(v) {
                          var $76 = {};
                          for (var $77 in v) {
                            if ({}.hasOwnProperty.call(v, $77)) {
                              $76[$77] = v[$77];
                            }
                            ;
                          }
                          ;
                          $76.subs = [escSub, scrollSub, resizeSub];
                          $76.postSub = new Just(psid);
                          return $76;
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var initialState5 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      side: input3.side,
      align: input3.align,
      offset: input3.offset,
      padding: input3.padding,
      style: input3.style,
      triggerHref: input3.triggerHref,
      wrapperClass: input3.wrapperClass,
      proseBefore: input3.proseBefore,
      proseAfter: input3.proseAfter,
      trigger: input3.trigger,
      content: input3.content,
      contentStyle: input3.contentStyle,
      triggerAttrs: input3.triggerAttrs,
      portalAttrs: input3.portalAttrs,
      placedSide: input3.side,
      placedAlign: input3.align,
      restoreEl: Nothing.value,
      subs: [],
      postSub: Nothing.value,
      contentId: ""
    };
  };
  var finalize3 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return function(v) {
      return bind20(liftEffect7(documentBody))(function(mbody) {
        return bind20(getHTMLElementRef(wrapperRef3))(function(mwrap) {
          if (mbody instanceof Just && mwrap instanceof Just) {
            return liftEffect7(afterFrame(adopt(mbody.value0)(toElement(mwrap.value0))));
          }
          ;
          return pure17(unit);
        });
      });
    };
  };
  var defaultStyle5 = {
    trigger: /* @__PURE__ */ cn("rdx-hover-card-trigger"),
    content: /* @__PURE__ */ cn("rdx-hover-card-content")
  };
  var defaultInput5 = /* @__PURE__ */ function() {
    return {
      open: Nothing.value,
      defaultOpen: false,
      side: Bottom.value,
      align: Center.value,
      offset: 8,
      padding: 8,
      style: defaultStyle5,
      triggerHref: "#",
      wrapperClass: cn(""),
      proseBefore: [],
      proseAfter: [],
      trigger: [],
      content: [],
      contentStyle: "",
      triggerAttrs: [],
      portalAttrs: []
    };
  }();
  var contentRef5 = "rdx-hover-card-content";
  var render5 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([span3([classes2(st.wrapperClass)])(append16(map30(fromPlainHTML)(st.proseBefore))(append16([a(append16([href4(st.triggerHref), ref2(triggerRef3), classes2(st.style.trigger), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("radix-popper-side")(sideName(st.placedSide)), dataAttr("radix-popper-align")(alignName(st.placedAlign)), onMouseEnter(function(v) {
      return Show.value;
    }), onMouseLeave(function(v) {
      return Hide.value;
    }), onFocus(function(v) {
      return Show.value;
    }), onBlur(function(v) {
      return Hide.value;
    })])(portalData5(st.triggerAttrs)))(map30(fromPlainHTML)(st.trigger))])(map30(fromPlainHTML)(st.proseAfter)))), div3([ref2(wrapperRef3), dataAttr("radix-popper-content-wrapper")(""), style(function() {
      if (open) {
        return "position: fixed;";
      }
      ;
      return "display:none;";
    }())])([div3(append16([ref2(contentRef5), classes2(st.style.content), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("side")(sideName(st.placedSide)), dataAttr("align")(alignName(st.placedAlign)), style(st.contentStyle), onMouseEnter(function(v) {
      return Show.value;
    }), onMouseLeave(function(v) {
      return Hide.value;
    })])(portalData5(st.portalAttrs)))(map30(fromPlainHTML)(st.content))])]);
  };
  var reposition3 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind20(get6)(function(st) {
      return bind20(getHTMLElementRef(triggerRef3))(function(manchor) {
        return bind20(getHTMLElementRef(wrapperRef3))(function(mwrap) {
          return bind20(getHTMLElementRef(contentRef5))(function(mfloat) {
            if (manchor instanceof Just && (mwrap instanceof Just && mfloat instanceof Just)) {
              return bind20(liftEffect7(positionWrapper({
                anchor: manchor.value0,
                wrapper: mwrap.value0,
                floating: mfloat.value0,
                side: st.side,
                align: st.align,
                offset: st.offset,
                padding: st.padding
              })))(function(placed) {
                return modify_7(function(v) {
                  var $89 = {};
                  for (var $90 in v) {
                    if ({}.hasOwnProperty.call(v, $90)) {
                      $89[$90] = v[$90];
                    }
                    ;
                  }
                  ;
                  $89.placedSide = placed.placement.side;
                  $89.placedAlign = placed.placement.align;
                  return $89;
                });
              });
            }
            ;
            return pure17(unit);
          });
        });
      });
    });
  };
  var closeCard = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind20(get6)(function(st) {
      return when10(current(st.ctrl))(discard8(traverse_11(unsubscribe2)(st.subs))(function() {
        return discard8(for_8(st.postSub)(unsubscribe2))(function() {
          return discard8(for_8(st.restoreEl)(function($111) {
            return liftEffect7(focus($111));
          }))(function() {
            return discard8(modify_7(function(v) {
              var $95 = {};
              for (var $96 in v) {
                if ({}.hasOwnProperty.call(v, $96)) {
                  $95[$96] = v[$96];
                }
                ;
              }
              ;
              $95.ctrl = change2(false)(st.ctrl).next;
              $95.restoreEl = Nothing.value;
              $95.subs = [];
              $95.postSub = Nothing.value;
              return $95;
            }))(function() {
              return raise(new OpenChanged5(false));
            });
          });
        });
      }));
    });
  };
  var handleAction5 = function(dictMonadEffect) {
    var useId2 = useId(monadEffectHalogenM(dictMonadEffect));
    var openCard1 = openCard(dictMonadEffect);
    var closeCard1 = closeCard(dictMonadEffect);
    var reposition1 = reposition3(dictMonadEffect);
    var finalize1 = finalize3(dictMonadEffect);
    return function(v) {
      if (v instanceof Initialize5) {
        return bind20(useId2)(function(cid) {
          return modify_7(function(v1) {
            var $99 = {};
            for (var $100 in v1) {
              if ({}.hasOwnProperty.call(v1, $100)) {
                $99[$100] = v1[$100];
              }
              ;
            }
            ;
            $99.contentId = cid;
            return $99;
          });
        });
      }
      ;
      if (v instanceof Receive6) {
        return modify_7(function(st) {
          var $102 = {};
          for (var $103 in st) {
            if ({}.hasOwnProperty.call(st, $103)) {
              $102[$103] = st[$103];
            }
            ;
          }
          ;
          $102.ctrl = sync(v.value0.open)(st.ctrl);
          $102.side = v.value0.side;
          $102.align = v.value0.align;
          $102.offset = v.value0.offset;
          $102.padding = v.value0.padding;
          $102.style = v.value0.style;
          $102.triggerHref = v.value0.triggerHref;
          $102.wrapperClass = v.value0.wrapperClass;
          $102.proseBefore = v.value0.proseBefore;
          $102.proseAfter = v.value0.proseAfter;
          $102.trigger = v.value0.trigger;
          $102.content = v.value0.content;
          $102.contentStyle = v.value0.contentStyle;
          $102.triggerAttrs = v.value0.triggerAttrs;
          $102.portalAttrs = v.value0.portalAttrs;
          return $102;
        });
      }
      ;
      if (v instanceof Show) {
        return openCard1;
      }
      ;
      if (v instanceof Hide) {
        return closeCard1;
      }
      ;
      if (v instanceof AfterOpen5) {
        return discard8(reposition1)(function() {
          return finalize1(true);
        });
      }
      ;
      if (v instanceof EscapePressed5) {
        return closeCard1;
      }
      ;
      if (v instanceof Reposition3) {
        return discard8(reposition1)(function() {
          return finalize1(false);
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.HoverCard (line 267, column 16 - line 300, column 19): " + [v.constructor.name]);
    };
  };
  var handleQuery5 = function(dictMonadEffect) {
    var openCard1 = openCard(dictMonadEffect);
    var closeCard1 = closeCard(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen5) {
        return discard8(function() {
          if (v.value0) {
            return openCard1;
          }
          ;
          return closeCard1;
        }())(function() {
          return pure17(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen5) {
        return bind20(get6)(function(st) {
          return pure17(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.HoverCard (line 368, column 15 - line 374, column 42): " + [v.constructor.name]);
    };
  };
  var component5 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState5,
      render: render5,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction5(dictMonadEffect),
        handleQuery: handleQuery5(dictMonadEffect),
        receive: function($112) {
          return Just.create(Receive6.create($112));
        },
        initialize: new Just(Initialize5.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Popover/index.js
  var bind21 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight7 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard9 = /* @__PURE__ */ discard(discardUnit);
  var discard16 = /* @__PURE__ */ discard9(bindHalogenM);
  var pure18 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map31 = /* @__PURE__ */ map(functorArray);
  var when11 = /* @__PURE__ */ when(applicativeEffect);
  var for_9 = /* @__PURE__ */ for_(applicativeEffect)(foldableMaybe);
  var $$void10 = /* @__PURE__ */ $$void(functorEffect);
  var get7 = /* @__PURE__ */ get(monadStateHalogenM);
  var when13 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind111 = /* @__PURE__ */ bind(bindEffect);
  var modify_8 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var map115 = /* @__PURE__ */ map(functorHalogenM);
  var map211 = /* @__PURE__ */ map(functorMaybe);
  var append17 = /* @__PURE__ */ append(semigroupArray);
  var type_22 = /* @__PURE__ */ type_17(isPropButtonType);
  var traverse_14 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableArray);
  var for_14 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var SetOpen6 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen6 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged6 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var Initialize6 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive7 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var TriggerClicked4 = /* @__PURE__ */ function() {
    function TriggerClicked6() {
    }
    ;
    TriggerClicked6.value = new TriggerClicked6();
    return TriggerClicked6;
  }();
  var AfterOpen6 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var EscapePressed6 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var PointerDown3 = /* @__PURE__ */ function() {
    function PointerDown5(value0) {
      this.value0 = value0;
    }
    ;
    PointerDown5.create = function(value0) {
      return new PointerDown5(value0);
    };
    return PointerDown5;
  }();
  var ContentKeyDown3 = /* @__PURE__ */ function() {
    function ContentKeyDown4(value0) {
      this.value0 = value0;
    }
    ;
    ContentKeyDown4.create = function(value0) {
      return new ContentKeyDown4(value0);
    };
    return ContentKeyDown4;
  }();
  var Reposition4 = /* @__PURE__ */ function() {
    function Reposition7() {
    }
    ;
    Reposition7.value = new Reposition7();
    return Reposition7;
  }();
  var wrapperRef4 = "rdx-popover-wrapper";
  var triggerRef4 = "rdx-popover-trigger";
  var scheduleAfterOpen6 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind21(liftEffect7(create3))(function(v) {
      return bind21(subscribe2(voidRight7(AfterOpen6.value)(v.emitter)))(function(sid) {
        return discard16(liftEffect7(afterFrame(notify(v.listener)(unit))))(function() {
          return pure18(sid);
        });
      });
    });
  };
  var portalData6 = /* @__PURE__ */ map31(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var initialState6 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      side: input3.side,
      align: input3.align,
      offset: input3.offset,
      padding: input3.padding,
      style: input3.style,
      trigger: input3.trigger,
      content: input3.content,
      contentStyle: input3.contentStyle,
      triggerAttrs: input3.triggerAttrs,
      portalAttrs: input3.portalAttrs,
      placedSide: input3.side,
      placedAlign: input3.align,
      restoreEl: Nothing.value,
      subs: [],
      postSub: Nothing.value,
      contentNode: Nothing.value,
      contentId: ""
    };
  };
  var defaultStyle6 = {
    trigger: /* @__PURE__ */ cn("rdx-popover-trigger"),
    content: /* @__PURE__ */ cn("rdx-popover-content")
  };
  var defaultInput6 = /* @__PURE__ */ function() {
    return {
      open: Nothing.value,
      defaultOpen: false,
      side: Bottom.value,
      align: Center.value,
      offset: 8,
      padding: 8,
      style: defaultStyle6,
      trigger: [],
      content: [],
      contentStyle: "",
      triggerAttrs: [],
      portalAttrs: []
    };
  }();
  var contentRef6 = "rdx-popover-content";
  var finalize4 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return function(focusToo) {
      return bind21(liftEffect7(documentBody))(function(mbody) {
        return bind21(getHTMLElementRef(wrapperRef4))(function(mwrap) {
          return bind21(getHTMLElementRef(contentRef6))(function(mc) {
            if (mbody instanceof Just && mwrap instanceof Just) {
              return liftEffect7(afterFrame(function __do12() {
                adopt(mbody.value0)(toElement(mwrap.value0))();
                return when11(focusToo)(function __do13() {
                  addFocusGuards();
                  return for_9(mc)(function(content3) {
                    return $$void10(captureFocus(content3));
                  })();
                })();
              }));
            }
            ;
            return pure18(unit);
          });
        });
      });
    };
  };
  var openPopover = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen6(dictMonadEffect);
    return bind21(get7)(function(st) {
      return when13(!current(st.ctrl))(bind21(liftEffect7(bind111(windowImpl)(document)))(function(doc) {
        return bind21(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard16(modify_8(function(v) {
            var $81 = {};
            for (var $82 in v) {
              if ({}.hasOwnProperty.call(v, $82)) {
                $81[$82] = v[$82];
              }
              ;
            }
            ;
            $81.ctrl = change2(true)(st.ctrl).next;
            $81.restoreEl = mprev;
            return $81;
          }))(function() {
            return discard16(raise(new OpenChanged6(true)))(function() {
              return bind21(map115(map211(toNode))(getHTMLElementRef(contentRef6)))(function(mcNode) {
                return bind21(liftEffect7(windowTarget))(function(win) {
                  var docTarget = toEventTarget(doc);
                  return bind21(subscribe2($$escape(docTarget)(EscapePressed6.value)))(function(escSub) {
                    return bind21(subscribe2(pointerDown(docTarget)(PointerDown3.create)))(function(ptrSub) {
                      return bind21(subscribe2(eventListener2("scroll")(win)(function(v) {
                        return new Just(Reposition4.value);
                      })))(function(scrollSub) {
                        return bind21(subscribe2(eventListener2("resize")(win)(function(v) {
                          return new Just(Reposition4.value);
                        })))(function(resizeSub) {
                          return bind21(scheduleAfterOpen1)(function(psid) {
                            return modify_8(function(v) {
                              var $84 = {};
                              for (var $85 in v) {
                                if ({}.hasOwnProperty.call(v, $85)) {
                                  $84[$85] = v[$85];
                                }
                                ;
                              }
                              ;
                              $84.contentNode = mcNode;
                              $84.subs = [escSub, ptrSub, scrollSub, resizeSub];
                              $84.postSub = new Just(psid);
                              return $84;
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var render6 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([button(append17([type_22(ButtonButton.value), ref2(triggerRef4), classes2(st.style.trigger), aria("expanded")(function() {
      if (open) {
        return "true";
      }
      ;
      return "false";
    }()), aria("haspopup")("dialog"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("radix-popper-side")(sideName(st.placedSide)), dataAttr("radix-popper-align")(alignName(st.placedAlign)), onClick(function(v) {
      return TriggerClicked4.value;
    })])(append17(function() {
      if (open) {
        return [aria("controls")(st.contentId)];
      }
      ;
      return [];
    }())(portalData6(st.triggerAttrs))))(map31(fromPlainHTML)(st.trigger)), div3([ref2(wrapperRef4), dataAttr("radix-popper-content-wrapper")(""), style(function() {
      if (open) {
        return "position: fixed;";
      }
      ;
      return "display:none;";
    }())])([div3(append17([ref2(contentRef6), id2(st.contentId), classes2(st.style.content), role("dialog"), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dataAttr("side")(sideName(st.placedSide)), dataAttr("align")(alignName(st.placedAlign)), tabIndex2(-1 | 0), style(st.contentStyle), onKeyDown(ContentKeyDown3.create)])(portalData6(st.portalAttrs)))(map31(fromPlainHTML)(st.content))])]);
  };
  var reposition4 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind21(get7)(function(st) {
      return bind21(getHTMLElementRef(triggerRef4))(function(manchor) {
        return bind21(getHTMLElementRef(wrapperRef4))(function(mwrap) {
          return bind21(getHTMLElementRef(contentRef6))(function(mfloat) {
            if (manchor instanceof Just && (mwrap instanceof Just && mfloat instanceof Just)) {
              return bind21(liftEffect7(positionWrapper({
                anchor: manchor.value0,
                wrapper: mwrap.value0,
                floating: mfloat.value0,
                side: st.side,
                align: st.align,
                offset: st.offset,
                padding: st.padding
              })))(function(placed) {
                return modify_8(function(v) {
                  var $95 = {};
                  for (var $96 in v) {
                    if ({}.hasOwnProperty.call(v, $96)) {
                      $95[$96] = v[$96];
                    }
                    ;
                  }
                  ;
                  $95.placedSide = placed.placement.side;
                  $95.placedAlign = placed.placement.align;
                  return $95;
                });
              });
            }
            ;
            return pure18(unit);
          });
        });
      });
    });
  };
  var closePopover = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind21(get7)(function(st) {
      return when13(current(st.ctrl))(discard16(traverse_14(unsubscribe2)(st.subs))(function() {
        return discard16(for_14(st.postSub)(unsubscribe2))(function() {
          return discard16(for_14(st.restoreEl)(function($120) {
            return liftEffect7(focus($120));
          }))(function() {
            return discard16(liftEffect7(removeFocusGuards))(function() {
              return discard16(modify_8(function(v) {
                var $101 = {};
                for (var $102 in v) {
                  if ({}.hasOwnProperty.call(v, $102)) {
                    $101[$102] = v[$102];
                  }
                  ;
                }
                ;
                $101.ctrl = change2(false)(st.ctrl).next;
                $101.restoreEl = Nothing.value;
                $101.subs = [];
                $101.postSub = Nothing.value;
                $101.contentNode = Nothing.value;
                return $101;
              }))(function() {
                return raise(new OpenChanged6(false));
              });
            });
          });
        });
      }));
    });
  };
  var handleAction6 = function(dictMonadEffect) {
    var monadEffectHalogenM2 = monadEffectHalogenM(dictMonadEffect);
    var useId2 = useId(monadEffectHalogenM2);
    var closePopover1 = closePopover(dictMonadEffect);
    var openPopover1 = openPopover(dictMonadEffect);
    var reposition1 = reposition4(dictMonadEffect);
    var finalize1 = finalize4(dictMonadEffect);
    var liftEffect7 = liftEffect(monadEffectHalogenM2);
    return function(v) {
      if (v instanceof Initialize6) {
        return bind21(useId2)(function(cid) {
          return modify_8(function(v1) {
            var $105 = {};
            for (var $106 in v1) {
              if ({}.hasOwnProperty.call(v1, $106)) {
                $105[$106] = v1[$106];
              }
              ;
            }
            ;
            $105.contentId = cid;
            return $105;
          });
        });
      }
      ;
      if (v instanceof Receive7) {
        return modify_8(function(st) {
          var $108 = {};
          for (var $109 in st) {
            if ({}.hasOwnProperty.call(st, $109)) {
              $108[$109] = st[$109];
            }
            ;
          }
          ;
          $108.ctrl = sync(v.value0.open)(st.ctrl);
          $108.side = v.value0.side;
          $108.align = v.value0.align;
          $108.offset = v.value0.offset;
          $108.padding = v.value0.padding;
          $108.style = v.value0.style;
          $108.trigger = v.value0.trigger;
          $108.content = v.value0.content;
          $108.contentStyle = v.value0.contentStyle;
          $108.triggerAttrs = v.value0.triggerAttrs;
          $108.portalAttrs = v.value0.portalAttrs;
          return $108;
        });
      }
      ;
      if (v instanceof TriggerClicked4) {
        return bind21(get7)(function(st) {
          var $112 = current(st.ctrl);
          if ($112) {
            return closePopover1;
          }
          ;
          return openPopover1;
        });
      }
      ;
      if (v instanceof AfterOpen6) {
        return discard16(reposition1)(function() {
          return finalize1(true);
        });
      }
      ;
      if (v instanceof EscapePressed6) {
        return closePopover1;
      }
      ;
      if (v instanceof PointerDown3) {
        return bind21(get7)(function(st) {
          return for_14(st.contentNode)(function(node) {
            return bind21(liftEffect7(isOutside(node)(v.value0)))(function(outside) {
              return when13(outside)(closePopover1);
            });
          });
        });
      }
      ;
      if (v instanceof ContentKeyDown3) {
        return bind21(getHTMLElementRef(contentRef6))(function(mnode) {
          return for_14(mnode)(function(node) {
            return bind21(liftEffect7(tabLoop(true)(node)(v.value0)))(function(handled) {
              return when13(handled)(liftEffect7(preventDefault(toEvent(v.value0))));
            });
          });
        });
      }
      ;
      if (v instanceof Reposition4) {
        return discard16(reposition1)(function() {
          return finalize1(false);
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Popover (line 250, column 16 - line 291, column 19): " + [v.constructor.name]);
    };
  };
  var handleQuery6 = function(dictMonadEffect) {
    var openPopover1 = openPopover(dictMonadEffect);
    var closePopover1 = closePopover(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen6) {
        return discard16(function() {
          if (v.value0) {
            return openPopover1;
          }
          ;
          return closePopover1;
        }())(function() {
          return pure18(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen6) {
        return bind21(get7)(function(st) {
          return pure18(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Popover (line 371, column 15 - line 377, column 42): " + [v.constructor.name]);
    };
  };
  var component6 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState6,
      render: render6,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction6(dictMonadEffect),
        handleQuery: handleQuery6(dictMonadEffect),
        receive: function($121) {
          return Just.create(Receive7.create($121));
        },
        initialize: new Just(Initialize6.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Select/index.js
  var map32 = /* @__PURE__ */ map(functorArray);
  var bind22 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight8 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard10 = /* @__PURE__ */ discard(discardUnit);
  var discard17 = /* @__PURE__ */ discard10(bindHalogenM);
  var pure19 = /* @__PURE__ */ pure(applicativeHalogenM);
  var show8 = /* @__PURE__ */ show(showInt);
  var append18 = /* @__PURE__ */ append(semigroupArray);
  var for_10 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var for_15 = /* @__PURE__ */ for_(applicativeEffect)(foldableMaybe);
  var get8 = /* @__PURE__ */ get(monadStateHalogenM);
  var when14 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind112 = /* @__PURE__ */ bind(bindEffect);
  var modify_9 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var map116 = /* @__PURE__ */ map(functorHalogenM);
  var map212 = /* @__PURE__ */ map(functorMaybe);
  var type_23 = /* @__PURE__ */ type_17(isPropButtonType);
  var traverse_15 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableArray);
  var applySecond8 = /* @__PURE__ */ applySecond(applyEffect);
  var traverse3 = /* @__PURE__ */ traverse(traversableArray)(applicativeHalogenM);
  var SetOpen7 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen7 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var SetValue = /* @__PURE__ */ function() {
    function SetValue2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetValue2.create = function(value0) {
      return function(value1) {
        return new SetValue2(value0, value1);
      };
    };
    return SetValue2;
  }();
  var GetValue = /* @__PURE__ */ function() {
    function GetValue2(value0) {
      this.value0 = value0;
    }
    ;
    GetValue2.create = function(value0) {
      return new GetValue2(value0);
    };
    return GetValue2;
  }();
  var OpenChanged7 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var ValueChanged = /* @__PURE__ */ function() {
    function ValueChanged2(value0) {
      this.value0 = value0;
    }
    ;
    ValueChanged2.create = function(value0) {
      return new ValueChanged2(value0);
    };
    return ValueChanged2;
  }();
  var Initialize7 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive8 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var TriggerClicked5 = /* @__PURE__ */ function() {
    function TriggerClicked6() {
    }
    ;
    TriggerClicked6.value = new TriggerClicked6();
    return TriggerClicked6;
  }();
  var AfterOpen7 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var EscapePressed7 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var PointerDown4 = /* @__PURE__ */ function() {
    function PointerDown5(value0) {
      this.value0 = value0;
    }
    ;
    PointerDown5.create = function(value0) {
      return new PointerDown5(value0);
    };
    return PointerDown5;
  }();
  var ListKeyDown = /* @__PURE__ */ function() {
    function ListKeyDown2(value0) {
      this.value0 = value0;
    }
    ;
    ListKeyDown2.create = function(value0) {
      return new ListKeyDown2(value0);
    };
    return ListKeyDown2;
  }();
  var ItemChosen = /* @__PURE__ */ function() {
    function ItemChosen2(value0) {
      this.value0 = value0;
    }
    ;
    ItemChosen2.create = function(value0) {
      return new ItemChosen2(value0);
    };
    return ItemChosen2;
  }();
  var Reposition5 = /* @__PURE__ */ function() {
    function Reposition7() {
    }
    ;
    Reposition7.value = new Reposition7();
    return Reposition7;
  }();
  var wrapperRef5 = "rdx-select-wrapper";
  var triggerRef5 = "rdx-select-trigger";
  var selectedLabel = function(st) {
    var v = find2(function(item) {
      return item.value === current(st.sel);
    })(st.items);
    if (v instanceof Just) {
      return map32(fromPlainHTML)(v.value0.label);
    }
    ;
    if (v instanceof Nothing) {
      return [];
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Radix.Select (line 255, column 20 - line 257, column 16): " + [v.constructor.name]);
  };
  var selectedIndex2 = function(st) {
    return fromMaybe(0)(findIndex(function(item) {
      return item.value === current(st.sel);
    })(st.items));
  };
  var scheduleAfterOpen7 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind22(liftEffect7(create3))(function(v) {
      return bind22(subscribe2(voidRight8(AfterOpen7.value)(v.emitter)))(function(sid) {
        return discard17(liftEffect7(queueMicrotask2(notify(v.listener)(unit))))(function() {
          return pure19(sid);
        });
      });
    });
  };
  var portalData7 = /* @__PURE__ */ map32(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var itemRef3 = function(pfx) {
    return function(i2) {
      return pfx + ("-item-" + show8(i2));
    };
  };
  var renderItem3 = function(st) {
    return function(idx) {
      return function(item) {
        var itemId = fromMaybe("")(index(st.itemIds)(idx));
        var isSelected = item.value === current(st.sel);
        return div3(append18([ref2(itemRef3(st.idPrefix)(idx)), role("option"), classes2(st.style.item), aria("labelledby")(itemId), aria("selected")(function() {
          if (isSelected) {
            return "true";
          }
          ;
          return "false";
        }()), dataState(function() {
          if (isSelected) {
            return "checked";
          }
          ;
          return "unchecked";
        }()), dataAttr("radix-collection-item")(""), tabIndex2(-1 | 0), onClick(function(v) {
          return new ItemChosen(item.value);
        })])(append18(function() {
          if (isSelected) {
            return [dataAttr("highlighted")("")];
          }
          ;
          return [];
        }())(function() {
          if (item.disabled) {
            return [dataAttr("disabled")(""), aria("disabled")("true")];
          }
          ;
          return [];
        }())))(append18(function() {
          if (isSelected) {
            return [span3([classes2(st.style.indicator), aria("hidden")("true")])(map32(fromPlainHTML)(st.checkIcon))];
          }
          ;
          return [];
        }())([span3([id2(itemId)])(map32(fromPlainHTML)(item.label))]));
      };
    };
  };
  var initialState7 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      sel: controllable(input3.value)(input3.defaultValue),
      items: input3.items,
      focused: 0,
      offset: input3.offset,
      padding: input3.padding,
      idPrefix: input3.idPrefix,
      style: input3.style,
      trigger: input3.trigger,
      groupLabel: input3.groupLabel,
      checkIcon: input3.checkIcon,
      contentStyle: input3.contentStyle,
      portalAttrs: input3.portalAttrs,
      restoreEl: Nothing.value,
      subs: [],
      postSub: Nothing.value,
      contentNode: Nothing.value,
      contentId: "",
      labelId: "",
      itemIds: []
    };
  };
  var focusItem = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return function(pfx) {
      return function(idx) {
        return bind22(getHTMLElementRef(itemRef3(pfx)(idx)))(function(mel) {
          return for_10(mel)(function($154) {
            return liftEffect7(focus($154));
          });
        });
      };
    };
  };
  var dir4 = /* @__PURE__ */ attr2("dir");
  var defaultStyle7 = {
    trigger: /* @__PURE__ */ cn("rdx-select-trigger"),
    value: /* @__PURE__ */ cn("rdx-select-value"),
    content: /* @__PURE__ */ cn("rdx-select-content"),
    scrollRoot: /* @__PURE__ */ cn("rdx-select-scroll-root"),
    scrollViewport: /* @__PURE__ */ cn("rdx-select-scroll-viewport"),
    group: /* @__PURE__ */ cn("rdx-select-group"),
    label: /* @__PURE__ */ cn("rdx-select-label"),
    item: /* @__PURE__ */ cn("rdx-select-item"),
    indicator: /* @__PURE__ */ cn("rdx-select-indicator")
  };
  var defaultInput7 = /* @__PURE__ */ function() {
    return {
      items: [],
      open: Nothing.value,
      defaultOpen: false,
      value: Nothing.value,
      defaultValue: "",
      offset: 4,
      padding: 8,
      idPrefix: "rdx-select",
      style: defaultStyle7,
      trigger: [],
      groupLabel: [],
      checkIcon: [],
      contentStyle: "",
      portalAttrs: []
    };
  }();
  var contentRef7 = "rdx-select-content";
  var finalize5 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind22(liftEffect7(documentBody))(function(mbody) {
      return bind22(getHTMLElementRef(wrapperRef5))(function(mwrap) {
        return bind22(getHTMLElementRef(contentRef7))(function(mcontent) {
          if (mbody instanceof Just && mwrap instanceof Just) {
            return liftEffect7(function __do12() {
              adopt(mbody.value0)(toElement(mwrap.value0))();
              lockScroll();
              addFocusGuards();
              hideOthers(mwrap.value0)();
              return for_15(mcontent)(focus)();
            });
          }
          ;
          return pure19(unit);
        });
      });
    });
  };
  var openMenu3 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen7(dictMonadEffect);
    return bind22(get8)(function(st) {
      return when14(!current(st.ctrl))(function() {
        var start2 = selectedIndex2(st);
        return bind22(liftEffect7(bind112(windowImpl)(document)))(function(doc) {
          return bind22(liftEffect7(activeElement(doc)))(function(mprev) {
            return discard17(modify_9(function(v) {
              var $100 = {};
              for (var $101 in v) {
                if ({}.hasOwnProperty.call(v, $101)) {
                  $100[$101] = v[$101];
                }
                ;
              }
              ;
              $100.ctrl = change2(true)(st.ctrl).next;
              $100.focused = start2;
              $100.restoreEl = mprev;
              return $100;
            }))(function() {
              return discard17(raise(new OpenChanged7(true)))(function() {
                return bind22(map116(map212(toNode))(getHTMLElementRef(contentRef7)))(function(mcNode) {
                  return bind22(liftEffect7(windowTarget))(function(win) {
                    var docTarget = toEventTarget(doc);
                    return bind22(subscribe2($$escape(docTarget)(EscapePressed7.value)))(function(escSub) {
                      return bind22(subscribe2(pointerDown(docTarget)(PointerDown4.create)))(function(ptrSub) {
                        return bind22(subscribe2(eventListener2("scroll")(win)(function(v) {
                          return new Just(Reposition5.value);
                        })))(function(scrollSub) {
                          return bind22(subscribe2(eventListener2("resize")(win)(function(v) {
                            return new Just(Reposition5.value);
                          })))(function(resizeSub) {
                            return bind22(scheduleAfterOpen1)(function(psid) {
                              return modify_9(function(v) {
                                var $103 = {};
                                for (var $104 in v) {
                                  if ({}.hasOwnProperty.call(v, $104)) {
                                    $103[$104] = v[$104];
                                  }
                                  ;
                                }
                                ;
                                $103.contentNode = mcNode;
                                $103.subs = [escSub, ptrSub, scrollSub, resizeSub];
                                $103.postSub = new Just(psid);
                                return $103;
                              });
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }());
    });
  };
  var render7 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([button(append18([type_23(ButtonButton.value), ref2(triggerRef5), classes2(st.style.trigger), role("combobox"), aria("autocomplete")("none"), aria("expanded")(function() {
      if (open) {
        return "true";
      }
      ;
      return "false";
    }()), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dir4("ltr"), onClick(function(v) {
      return TriggerClicked5.value;
    })])(function() {
      if (open) {
        return [aria("controls")(st.contentId)];
      }
      ;
      return [];
    }()))(append18([span3([classes2(st.style.value)])([span3([style("pointer-events: none;")])(selectedLabel(st))])])(map32(fromPlainHTML)(st.trigger))), div3([ref2(wrapperRef5), style(function() {
      if (open) {
        return "";
      }
      ;
      return "display:none;";
    }())])([div3(append18([ref2(contentRef7), id2(st.contentId), role("listbox"), classes2(st.style.content), dataState(function() {
      if (open) {
        return "open";
      }
      ;
      return "closed";
    }()), dir4("ltr"), tabIndex2(-1 | 0), style(st.contentStyle), onKeyDown(ListKeyDown.create)])(portalData7(st.portalAttrs)))([div3([classes2(st.style.scrollRoot), dir4("ltr"), style("position: relative; --radix-scroll-area-corner-width: 0px; --radix-scroll-area-corner-height: 0px;")])([div3([classes2(st.style.scrollViewport), dataAttr("radix-scroll-area-viewport")(""), dataAttr("radix-select-viewport")(""), role("presentation"), style("overflow: hidden auto; position: relative; flex: 1 1 0%;")])([div3([style("min-width: 100%; display: table;")])([div3([classes2(st.style.group), role("group"), aria("labelledby")(st.labelId)])(append18(function() {
      var $111 = $$null(st.groupLabel);
      if ($111) {
        return [];
      }
      ;
      return [div3([classes2(st.style.label), id2(st.labelId)])(map32(fromPlainHTML)(st.groupLabel))];
    }())(mapWithIndex2(renderItem3(st))(st.items)))])])])])])]);
  };
  var reposition5 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind22(get8)(function(st) {
      return bind22(getHTMLElementRef(triggerRef5))(function(mtrigger) {
        return bind22(getHTMLElementRef(wrapperRef5))(function(mwrapper) {
          return bind22(getHTMLElementRef(contentRef7))(function(mcontent) {
            return bind22(getHTMLElementRef(itemRef3(st.idPrefix)(selectedIndex2(st))))(function(msel) {
              if (mtrigger instanceof Just && (mwrapper instanceof Just && (mcontent instanceof Just && msel instanceof Just))) {
                return liftEffect7(positionItemAligned({
                  trigger: mtrigger.value0,
                  wrapper: mwrapper.value0,
                  content: mcontent.value0,
                  selectedItem: msel.value0,
                  padding: st.padding
                }));
              }
              ;
              return pure19(unit);
            });
          });
        });
      });
    });
  };
  var closeMenu3 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind22(get8)(function(st) {
      return when14(current(st.ctrl))(discard17(traverse_15(unsubscribe2)(st.subs))(function() {
        return discard17(for_10(st.postSub)(unsubscribe2))(function() {
          return discard17(liftEffect7(applySecond8(applySecond8(showOthers)(removeFocusGuards))(unlockScroll)))(function() {
            return discard17(for_10(st.restoreEl)(function($155) {
              return liftEffect7(focus($155));
            }))(function() {
              return discard17(modify_9(function(v) {
                var $120 = {};
                for (var $121 in v) {
                  if ({}.hasOwnProperty.call(v, $121)) {
                    $120[$121] = v[$121];
                  }
                  ;
                }
                ;
                $120.ctrl = change2(false)(st.ctrl).next;
                $120.restoreEl = Nothing.value;
                $120.subs = [];
                $120.postSub = Nothing.value;
                $120.contentNode = Nothing.value;
                return $120;
              }))(function() {
                return raise(new OpenChanged7(false));
              });
            });
          });
        });
      }));
    });
  };
  var handleAction7 = function(dictMonadEffect) {
    var monadEffectHalogenM2 = monadEffectHalogenM(dictMonadEffect);
    var useId2 = useId(monadEffectHalogenM2);
    var closeMenu1 = closeMenu3(dictMonadEffect);
    var openMenu1 = openMenu3(dictMonadEffect);
    var reposition1 = reposition5(dictMonadEffect);
    var finalize1 = finalize5(dictMonadEffect);
    var liftEffect7 = liftEffect(monadEffectHalogenM2);
    var focusItem1 = focusItem(dictMonadEffect);
    return function(v) {
      if (v instanceof Initialize7) {
        return bind22(get8)(function(st) {
          return bind22(useId2)(function(cid) {
            return bind22(useId2)(function(lid) {
              return bind22(traverse3($$const(useId2))(st.items))(function(iids) {
                return modify_9(function(v1) {
                  var $124 = {};
                  for (var $125 in v1) {
                    if ({}.hasOwnProperty.call(v1, $125)) {
                      $124[$125] = v1[$125];
                    }
                    ;
                  }
                  ;
                  $124.contentId = cid;
                  $124.labelId = lid;
                  $124.itemIds = iids;
                  return $124;
                });
              });
            });
          });
        });
      }
      ;
      if (v instanceof Receive8) {
        return modify_9(function(st) {
          var $127 = {};
          for (var $128 in st) {
            if ({}.hasOwnProperty.call(st, $128)) {
              $127[$128] = st[$128];
            }
            ;
          }
          ;
          $127.ctrl = sync(v.value0.open)(st.ctrl);
          $127.sel = sync(v.value0.value)(st.sel);
          $127.items = v.value0.items;
          $127.offset = v.value0.offset;
          $127.padding = v.value0.padding;
          $127.idPrefix = v.value0.idPrefix;
          $127.style = v.value0.style;
          $127.trigger = v.value0.trigger;
          $127.groupLabel = v.value0.groupLabel;
          $127.checkIcon = v.value0.checkIcon;
          $127.contentStyle = v.value0.contentStyle;
          $127.portalAttrs = v.value0.portalAttrs;
          return $127;
        });
      }
      ;
      if (v instanceof TriggerClicked5) {
        return bind22(get8)(function(st) {
          var $131 = current(st.ctrl);
          if ($131) {
            return closeMenu1;
          }
          ;
          return openMenu1;
        });
      }
      ;
      if (v instanceof AfterOpen7) {
        return discard17(reposition1)(function() {
          return finalize1;
        });
      }
      ;
      if (v instanceof EscapePressed7) {
        return closeMenu1;
      }
      ;
      if (v instanceof PointerDown4) {
        return bind22(get8)(function(st) {
          return for_10(st.contentNode)(function(node) {
            return bind22(liftEffect7(isOutside(node)(v.value0)))(function(outside) {
              return when14(outside)(closeMenu1);
            });
          });
        });
      }
      ;
      if (v instanceof ListKeyDown) {
        return bind22(get8)(function(st) {
          var pos = {
            count: length(st.items),
            current: st.focused
          };
          var cfg = {
            orientation: Vertical.value,
            dir: LTR.value,
            loop: true
          };
          var v1 = navigate(cfg)(pos)(key(v.value0));
          if (v1 instanceof Stay) {
            return pure19(unit);
          }
          ;
          if (v1 instanceof MoveTo) {
            return discard17(modify_9(function(v2) {
              var $134 = {};
              for (var $135 in v2) {
                if ({}.hasOwnProperty.call(v2, $135)) {
                  $134[$135] = v2[$135];
                }
                ;
              }
              ;
              $134.focused = v1.value0;
              return $134;
            }))(function() {
              return focusItem1(st.idPrefix)(v1.value0);
            });
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Radix.Select (line 405, column 5 - line 409, column 34): " + [v1.constructor.name]);
        });
      }
      ;
      if (v instanceof ItemChosen) {
        return bind22(get8)(function(st) {
          var res = change2(v.value0)(st.sel);
          return discard17(modify_9(function(v1) {
            var $139 = {};
            for (var $140 in v1) {
              if ({}.hasOwnProperty.call(v1, $140)) {
                $139[$140] = v1[$140];
              }
              ;
            }
            ;
            $139.sel = res.next;
            return $139;
          }))(function() {
            return discard17(raise(new ValueChanged(res.emit)))(function() {
              return closeMenu1;
            });
          });
        });
      }
      ;
      if (v instanceof Reposition5) {
        return reposition1;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Select (line 362, column 16 - line 418, column 27): " + [v.constructor.name]);
    };
  };
  var handleQuery7 = function(dictMonadEffect) {
    var openMenu1 = openMenu3(dictMonadEffect);
    var closeMenu1 = closeMenu3(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen7) {
        return discard17(function() {
          if (v.value0) {
            return openMenu1;
          }
          ;
          return closeMenu1;
        }())(function() {
          return pure19(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen7) {
        return bind22(get8)(function(st) {
          return pure19(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      if (v instanceof SetValue) {
        return bind22(get8)(function(st) {
          var res = change2(v.value0)(st.sel);
          return discard17(modify_9(function(v2) {
            var $148 = {};
            for (var $149 in v2) {
              if ({}.hasOwnProperty.call(v2, $149)) {
                $148[$149] = v2[$149];
              }
              ;
            }
            ;
            $148.sel = res.next;
            return $148;
          }))(function() {
            return discard17(raise(new ValueChanged(res.emit)))(function() {
              return pure19(new Just(v.value1));
            });
          });
        });
      }
      ;
      if (v instanceof GetValue) {
        return bind22(get8)(function(st) {
          return pure19(new Just(v.value0(current(st.sel))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Select (line 505, column 15 - line 520, column 41): " + [v.constructor.name]);
    };
  };
  var component7 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState7,
      render: render7,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction7(dictMonadEffect),
        handleQuery: handleQuery7(dictMonadEffect),
        receive: function($156) {
          return Just.create(Receive8.create($156));
        },
        initialize: new Just(Initialize7.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Radix.Tooltip/index.js
  var bind23 = /* @__PURE__ */ bind(bindHalogenM);
  var voidRight9 = /* @__PURE__ */ voidRight(functorEmitter);
  var discard11 = /* @__PURE__ */ discard(discardUnit)(bindHalogenM);
  var pure20 = /* @__PURE__ */ pure(applicativeHalogenM);
  var map33 = /* @__PURE__ */ map(functorArray);
  var get9 = /* @__PURE__ */ get(monadStateHalogenM);
  var when15 = /* @__PURE__ */ when(applicativeHalogenM);
  var bind113 = /* @__PURE__ */ bind(bindEffect);
  var modify_10 = /* @__PURE__ */ modify_2(monadStateHalogenM);
  var traverse_16 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableArray);
  var for_11 = /* @__PURE__ */ for_(applicativeHalogenM)(foldableMaybe);
  var append19 = /* @__PURE__ */ append(semigroupArray);
  var SetOpen8 = /* @__PURE__ */ function() {
    function SetOpen9(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    SetOpen9.create = function(value0) {
      return function(value1) {
        return new SetOpen9(value0, value1);
      };
    };
    return SetOpen9;
  }();
  var GetOpen8 = /* @__PURE__ */ function() {
    function GetOpen9(value0) {
      this.value0 = value0;
    }
    ;
    GetOpen9.create = function(value0) {
      return new GetOpen9(value0);
    };
    return GetOpen9;
  }();
  var OpenChanged8 = /* @__PURE__ */ function() {
    function OpenChanged9(value0) {
      this.value0 = value0;
    }
    ;
    OpenChanged9.create = function(value0) {
      return new OpenChanged9(value0);
    };
    return OpenChanged9;
  }();
  var Initialize8 = /* @__PURE__ */ function() {
    function Initialize9() {
    }
    ;
    Initialize9.value = new Initialize9();
    return Initialize9;
  }();
  var Receive9 = /* @__PURE__ */ function() {
    function Receive10(value0) {
      this.value0 = value0;
    }
    ;
    Receive10.create = function(value0) {
      return new Receive10(value0);
    };
    return Receive10;
  }();
  var Show2 = /* @__PURE__ */ function() {
    function Show3() {
    }
    ;
    Show3.value = new Show3();
    return Show3;
  }();
  var Hide2 = /* @__PURE__ */ function() {
    function Hide3() {
    }
    ;
    Hide3.value = new Hide3();
    return Hide3;
  }();
  var AfterOpen8 = /* @__PURE__ */ function() {
    function AfterOpen9() {
    }
    ;
    AfterOpen9.value = new AfterOpen9();
    return AfterOpen9;
  }();
  var Reposition6 = /* @__PURE__ */ function() {
    function Reposition7() {
    }
    ;
    Reposition7.value = new Reposition7();
    return Reposition7;
  }();
  var EscapePressed8 = /* @__PURE__ */ function() {
    function EscapePressed9() {
    }
    ;
    EscapePressed9.value = new EscapePressed9();
    return EscapePressed9;
  }();
  var wrapperRef6 = "rdx-tooltip-wrapper";
  var visuallyHiddenStyle = "position: absolute; border: 0px; width: 1px; height: 1px; padding: 0px; margin: -1px; overflow: hidden; clip: rect(0px, 0px, 0px, 0px); white-space: nowrap; overflow-wrap: normal;";
  var triggerRef6 = "rdx-tooltip-trigger";
  var scheduleAfterOpen8 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind23(liftEffect7(create3))(function(v) {
      return bind23(subscribe2(voidRight9(AfterOpen8.value)(v.emitter)))(function(sid) {
        return discard11(liftEffect7(afterFrame(notify(v.listener)(unit))))(function() {
          return pure20(sid);
        });
      });
    });
  };
  var portalData8 = /* @__PURE__ */ map33(function(v) {
    return attr2("data-" + v.value0)(v.value1);
  });
  var openTooltip = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    var scheduleAfterOpen1 = scheduleAfterOpen8(dictMonadEffect);
    return bind23(get9)(function(st) {
      return when15(!current(st.ctrl))(bind23(liftEffect7(bind113(windowImpl)(document)))(function(doc) {
        return bind23(liftEffect7(activeElement(doc)))(function(mprev) {
          return discard11(modify_10(function(v) {
            var $71 = {};
            for (var $72 in v) {
              if ({}.hasOwnProperty.call(v, $72)) {
                $71[$72] = v[$72];
              }
              ;
            }
            ;
            $71.ctrl = change2(true)(st.ctrl).next;
            $71.restoreEl = mprev;
            return $71;
          }))(function() {
            return discard11(raise(new OpenChanged8(true)))(function() {
              return bind23(liftEffect7(windowTarget))(function(win) {
                var docTarget = toEventTarget(doc);
                return bind23(subscribe2($$escape(docTarget)(EscapePressed8.value)))(function(escSub) {
                  return bind23(subscribe2(eventListener2("scroll")(win)(function(v) {
                    return new Just(Reposition6.value);
                  })))(function(scrollSub) {
                    return bind23(subscribe2(eventListener2("resize")(win)(function(v) {
                      return new Just(Reposition6.value);
                    })))(function(resizeSub) {
                      return bind23(scheduleAfterOpen1)(function(psid) {
                        return modify_10(function(v) {
                          var $74 = {};
                          for (var $75 in v) {
                            if ({}.hasOwnProperty.call(v, $75)) {
                              $74[$75] = v[$75];
                            }
                            ;
                          }
                          ;
                          $74.subs = [escSub, scrollSub, resizeSub];
                          $74.postSub = new Just(psid);
                          return $74;
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      }));
    });
  };
  var initialState8 = function(input3) {
    return {
      ctrl: controllable(input3.open)(input3.defaultOpen),
      side: input3.side,
      align: input3.align,
      offset: input3.offset,
      padding: input3.padding,
      style: input3.style,
      trigger: input3.trigger,
      content: input3.content,
      contentStyle: input3.contentStyle,
      arrow: input3.arrow,
      triggerAttrs: input3.triggerAttrs,
      portalAttrs: input3.portalAttrs,
      placedSide: input3.side,
      placedAlign: input3.align,
      restoreEl: Nothing.value,
      subs: [],
      postSub: Nothing.value,
      contentId: ""
    };
  };
  var finalize6 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return function(v) {
      return bind23(liftEffect7(documentBody))(function(mbody) {
        return bind23(getHTMLElementRef(wrapperRef6))(function(mwrap) {
          if (mbody instanceof Just && mwrap instanceof Just) {
            return liftEffect7(afterFrame(adopt(mbody.value0)(toElement(mwrap.value0))));
          }
          ;
          return pure20(unit);
        });
      });
    };
  };
  var defaultStyle8 = {
    trigger: /* @__PURE__ */ cn("rdx-tooltip-trigger"),
    content: /* @__PURE__ */ cn("rdx-tooltip-content")
  };
  var defaultInput8 = /* @__PURE__ */ function() {
    return {
      open: Nothing.value,
      defaultOpen: false,
      side: Top.value,
      align: Center.value,
      offset: 4,
      padding: 8,
      style: defaultStyle8,
      trigger: [],
      content: [],
      contentStyle: "",
      arrow: [],
      triggerAttrs: [],
      portalAttrs: []
    };
  }();
  var contentRef8 = "rdx-tooltip-content";
  var closeTooltip = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind23(get9)(function(st) {
      return when15(current(st.ctrl))(discard11(traverse_16(unsubscribe2)(st.subs))(function() {
        return discard11(for_11(st.postSub)(unsubscribe2))(function() {
          return discard11(for_11(st.restoreEl)(function($110) {
            return liftEffect7(focus($110));
          }))(function() {
            return discard11(modify_10(function(v) {
              var $81 = {};
              for (var $82 in v) {
                if ({}.hasOwnProperty.call(v, $82)) {
                  $81[$82] = v[$82];
                }
                ;
              }
              ;
              $81.ctrl = change2(false)(st.ctrl).next;
              $81.restoreEl = Nothing.value;
              $81.subs = [];
              $81.postSub = Nothing.value;
              return $81;
            }))(function() {
              return raise(new OpenChanged8(false));
            });
          });
        });
      }));
    });
  };
  var handleQuery8 = function(dictMonadEffect) {
    var openTooltip1 = openTooltip(dictMonadEffect);
    var closeTooltip1 = closeTooltip(dictMonadEffect);
    return function(v) {
      if (v instanceof SetOpen8) {
        return discard11(function() {
          if (v.value0) {
            return openTooltip1;
          }
          ;
          return closeTooltip1;
        }())(function() {
          return pure20(new Just(v.value1));
        });
      }
      ;
      if (v instanceof GetOpen8) {
        return bind23(get9)(function(st) {
          return pure20(new Just(v.value0(current(st.ctrl))));
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Tooltip (line 359, column 15 - line 365, column 42): " + [v.constructor.name]);
    };
  };
  var arrowRef = "rdx-tooltip-arrow";
  var render8 = function(st) {
    var open = current(st.ctrl);
    return div3([style("display:contents")])([button(append19([ref2(triggerRef6), classes2(st.style.trigger), aria("describedby")(st.contentId), dataState(function() {
      if (open) {
        return "delayed-open";
      }
      ;
      return "closed";
    }()), dataAttr("radix-popper-side")(sideName(st.placedSide)), dataAttr("radix-popper-align")(alignName(st.placedAlign)), onMouseEnter(function(v) {
      return Show2.value;
    }), onMouseLeave(function(v) {
      return Hide2.value;
    }), onFocus(function(v) {
      return Show2.value;
    }), onBlur(function(v) {
      return Hide2.value;
    })])(portalData8(st.triggerAttrs)))(map33(fromPlainHTML)(st.trigger)), div3([ref2(wrapperRef6), dataAttr("radix-popper-content-wrapper")(""), style(function() {
      if (open) {
        return "position: fixed;";
      }
      ;
      return "display:none;";
    }())])([div3(append19([ref2(contentRef8), classes2(st.style.content), dataState(function() {
      if (open) {
        return "delayed-open";
      }
      ;
      return "closed";
    }()), dataAttr("side")(sideName(st.placedSide)), dataAttr("align")(alignName(st.placedAlign)), style(st.contentStyle)])(portalData8(st.portalAttrs)))(append19(map33(fromPlainHTML)(st.content))(append19(function() {
      var $92 = $$null(st.arrow);
      if ($92) {
        return [];
      }
      ;
      return [span3([ref2(arrowRef), style("position: absolute;")])(map33(fromPlainHTML)(st.arrow))];
    }())([span3([id2(st.contentId), role("tooltip"), style(visuallyHiddenStyle)])(map33(fromPlainHTML)(st.content))])))])]);
  };
  var reposition6 = function(dictMonadEffect) {
    var liftEffect7 = liftEffect(monadEffectHalogenM(dictMonadEffect));
    return bind23(get9)(function(st) {
      return bind23(getHTMLElementRef(triggerRef6))(function(manchor) {
        return bind23(getHTMLElementRef(wrapperRef6))(function(mwrap) {
          return bind23(getHTMLElementRef(contentRef8))(function(mfloat) {
            if (manchor instanceof Just && (mwrap instanceof Just && mfloat instanceof Just)) {
              return bind23(liftEffect7(positionWrapper({
                anchor: manchor.value0,
                wrapper: mwrap.value0,
                floating: mfloat.value0,
                side: st.side,
                align: st.align,
                offset: st.offset,
                padding: st.padding
              })))(function(placed) {
                return discard11(modify_10(function(v) {
                  var $96 = {};
                  for (var $97 in v) {
                    if ({}.hasOwnProperty.call(v, $97)) {
                      $96[$97] = v[$97];
                    }
                    ;
                  }
                  ;
                  $96.placedSide = placed.placement.side;
                  $96.placedAlign = placed.placement.align;
                  return $96;
                }))(function() {
                  return bind23(getHTMLElementRef(arrowRef))(function(marrow) {
                    return for_11(marrow)(function(arrow) {
                      return liftEffect7(positionArrow({
                        anchor: manchor.value0,
                        floating: mfloat.value0,
                        arrow,
                        side: placed.placement.side,
                        padding: st.padding
                      }));
                    });
                  });
                });
              });
            }
            ;
            return pure20(unit);
          });
        });
      });
    });
  };
  var handleAction8 = function(dictMonadEffect) {
    var useId2 = useId(monadEffectHalogenM(dictMonadEffect));
    var openTooltip1 = openTooltip(dictMonadEffect);
    var closeTooltip1 = closeTooltip(dictMonadEffect);
    var reposition1 = reposition6(dictMonadEffect);
    var finalize1 = finalize6(dictMonadEffect);
    return function(v) {
      if (v instanceof Initialize8) {
        return bind23(useId2)(function(cid) {
          return modify_10(function(v1) {
            var $103 = {};
            for (var $104 in v1) {
              if ({}.hasOwnProperty.call(v1, $104)) {
                $103[$104] = v1[$104];
              }
              ;
            }
            ;
            $103.contentId = cid;
            return $103;
          });
        });
      }
      ;
      if (v instanceof Receive9) {
        return modify_10(function(st) {
          var $106 = {};
          for (var $107 in st) {
            if ({}.hasOwnProperty.call(st, $107)) {
              $106[$107] = st[$107];
            }
            ;
          }
          ;
          $106.ctrl = sync(v.value0.open)(st.ctrl);
          $106.side = v.value0.side;
          $106.align = v.value0.align;
          $106.offset = v.value0.offset;
          $106.padding = v.value0.padding;
          $106.style = v.value0.style;
          $106.trigger = v.value0.trigger;
          $106.content = v.value0.content;
          $106.contentStyle = v.value0.contentStyle;
          $106.arrow = v.value0.arrow;
          $106.triggerAttrs = v.value0.triggerAttrs;
          $106.portalAttrs = v.value0.portalAttrs;
          return $106;
        });
      }
      ;
      if (v instanceof Show2) {
        return openTooltip1;
      }
      ;
      if (v instanceof Hide2) {
        return closeTooltip1;
      }
      ;
      if (v instanceof AfterOpen8) {
        return discard11(reposition1)(function() {
          return finalize1(true);
        });
      }
      ;
      if (v instanceof EscapePressed8) {
        return closeTooltip1;
      }
      ;
      if (v instanceof Reposition6) {
        return discard11(reposition1)(function() {
          return finalize1(false);
        });
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Radix.Tooltip (line 253, column 16 - line 285, column 19): " + [v.constructor.name]);
    };
  };
  var component8 = function(dictMonadEffect) {
    return mkComponent({
      initialState: initialState8,
      render: render8,
      "eval": mkEval({
        finalize: defaultEval.finalize,
        handleAction: handleAction8(dictMonadEffect),
        handleQuery: handleQuery8(dictMonadEffect),
        receive: function($111) {
          return Just.create(Receive9.create($111));
        },
        initialize: new Just(Initialize8.value)
      })
    });
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Themes.Prop/index.js
  var insert5 = /* @__PURE__ */ insert(ordString);
  var append5 = /* @__PURE__ */ append(semigroupArray);
  var foldl4 = /* @__PURE__ */ foldl(foldableArray);
  var map34 = /* @__PURE__ */ map(functorArray);
  var toUnfoldable3 = /* @__PURE__ */ toUnfoldable(unfoldableArray);
  var Class = /* @__PURE__ */ function() {
    function Class2(value0) {
      this.value0 = value0;
    }
    ;
    Class2.create = function(value0) {
      return new Class2(value0);
    };
    return Class2;
  }();
  var Size = /* @__PURE__ */ function() {
    function Size2(value0) {
      this.value0 = value0;
    }
    ;
    Size2.create = function(value0) {
      return new Size2(value0);
    };
    return Size2;
  }();
  var Variant = /* @__PURE__ */ function() {
    function Variant2(value0) {
      this.value0 = value0;
    }
    ;
    Variant2.create = function(value0) {
      return new Variant2(value0);
    };
    return Variant2;
  }();
  var Weight = /* @__PURE__ */ function() {
    function Weight2(value0) {
      this.value0 = value0;
    }
    ;
    Weight2.create = function(value0) {
      return new Weight2(value0);
    };
    return Weight2;
  }();
  var Trim = /* @__PURE__ */ function() {
    function Trim2(value0) {
      this.value0 = value0;
    }
    ;
    Trim2.create = function(value0) {
      return new Trim2(value0);
    };
    return Trim2;
  }();
  var Display = /* @__PURE__ */ function() {
    function Display2(value0) {
      this.value0 = value0;
    }
    ;
    Display2.create = function(value0) {
      return new Display2(value0);
    };
    return Display2;
  }();
  var Direction = /* @__PURE__ */ function() {
    function Direction2(value0) {
      this.value0 = value0;
    }
    ;
    Direction2.create = function(value0) {
      return new Direction2(value0);
    };
    return Direction2;
  }();
  var Align = /* @__PURE__ */ function() {
    function Align2(value0) {
      this.value0 = value0;
    }
    ;
    Align2.create = function(value0) {
      return new Align2(value0);
    };
    return Align2;
  }();
  var Justify = /* @__PURE__ */ function() {
    function Justify2(value0) {
      this.value0 = value0;
    }
    ;
    Justify2.create = function(value0) {
      return new Justify2(value0);
    };
    return Justify2;
  }();
  var Wrap = /* @__PURE__ */ function() {
    function Wrap2(value0) {
      this.value0 = value0;
    }
    ;
    Wrap2.create = function(value0) {
      return new Wrap2(value0);
    };
    return Wrap2;
  }();
  var Gap = /* @__PURE__ */ function() {
    function Gap2(value0) {
      this.value0 = value0;
    }
    ;
    Gap2.create = function(value0) {
      return new Gap2(value0);
    };
    return Gap2;
  }();
  var Position = /* @__PURE__ */ function() {
    function Position2(value0) {
      this.value0 = value0;
    }
    ;
    Position2.create = function(value0) {
      return new Position2(value0);
    };
    return Position2;
  }();
  var Columns = /* @__PURE__ */ function() {
    function Columns2(value0) {
      this.value0 = value0;
    }
    ;
    Columns2.create = function(value0) {
      return new Columns2(value0);
    };
    return Columns2;
  }();
  var Rows = /* @__PURE__ */ function() {
    function Rows2(value0) {
      this.value0 = value0;
    }
    ;
    Rows2.create = function(value0) {
      return new Rows2(value0);
    };
    return Rows2;
  }();
  var Flow = /* @__PURE__ */ function() {
    function Flow2(value0) {
      this.value0 = value0;
    }
    ;
    Flow2.create = function(value0) {
      return new Flow2(value0);
    };
    return Flow2;
  }();
  var AlignContent = /* @__PURE__ */ function() {
    function AlignContent2(value0) {
      this.value0 = value0;
    }
    ;
    AlignContent2.create = function(value0) {
      return new AlignContent2(value0);
    };
    return AlignContent2;
  }();
  var JustifyItems = /* @__PURE__ */ function() {
    function JustifyItems2(value0) {
      this.value0 = value0;
    }
    ;
    JustifyItems2.create = function(value0) {
      return new JustifyItems2(value0);
    };
    return JustifyItems2;
  }();
  var Side = /* @__PURE__ */ function() {
    function Side2(value0) {
      this.value0 = value0;
    }
    ;
    Side2.create = function(value0) {
      return new Side2(value0);
    };
    return Side2;
  }();
  var Clip = /* @__PURE__ */ function() {
    function Clip2(value0) {
      this.value0 = value0;
    }
    ;
    Clip2.create = function(value0) {
      return new Clip2(value0);
    };
    return Clip2;
  }();
  var M = /* @__PURE__ */ function() {
    function M2(value0) {
      this.value0 = value0;
    }
    ;
    M2.create = function(value0) {
      return new M2(value0);
    };
    return M2;
  }();
  var Mx = /* @__PURE__ */ function() {
    function Mx2(value0) {
      this.value0 = value0;
    }
    ;
    Mx2.create = function(value0) {
      return new Mx2(value0);
    };
    return Mx2;
  }();
  var My = /* @__PURE__ */ function() {
    function My2(value0) {
      this.value0 = value0;
    }
    ;
    My2.create = function(value0) {
      return new My2(value0);
    };
    return My2;
  }();
  var Mt = /* @__PURE__ */ function() {
    function Mt2(value0) {
      this.value0 = value0;
    }
    ;
    Mt2.create = function(value0) {
      return new Mt2(value0);
    };
    return Mt2;
  }();
  var Mr = /* @__PURE__ */ function() {
    function Mr2(value0) {
      this.value0 = value0;
    }
    ;
    Mr2.create = function(value0) {
      return new Mr2(value0);
    };
    return Mr2;
  }();
  var Mb = /* @__PURE__ */ function() {
    function Mb2(value0) {
      this.value0 = value0;
    }
    ;
    Mb2.create = function(value0) {
      return new Mb2(value0);
    };
    return Mb2;
  }();
  var Ml = /* @__PURE__ */ function() {
    function Ml2(value0) {
      this.value0 = value0;
    }
    ;
    Ml2.create = function(value0) {
      return new Ml2(value0);
    };
    return Ml2;
  }();
  var P = /* @__PURE__ */ function() {
    function P2(value0) {
      this.value0 = value0;
    }
    ;
    P2.create = function(value0) {
      return new P2(value0);
    };
    return P2;
  }();
  var Px = /* @__PURE__ */ function() {
    function Px2(value0) {
      this.value0 = value0;
    }
    ;
    Px2.create = function(value0) {
      return new Px2(value0);
    };
    return Px2;
  }();
  var Py = /* @__PURE__ */ function() {
    function Py2(value0) {
      this.value0 = value0;
    }
    ;
    Py2.create = function(value0) {
      return new Py2(value0);
    };
    return Py2;
  }();
  var Pt = /* @__PURE__ */ function() {
    function Pt2(value0) {
      this.value0 = value0;
    }
    ;
    Pt2.create = function(value0) {
      return new Pt2(value0);
    };
    return Pt2;
  }();
  var Pr = /* @__PURE__ */ function() {
    function Pr2(value0) {
      this.value0 = value0;
    }
    ;
    Pr2.create = function(value0) {
      return new Pr2(value0);
    };
    return Pr2;
  }();
  var Pb = /* @__PURE__ */ function() {
    function Pb2(value0) {
      this.value0 = value0;
    }
    ;
    Pb2.create = function(value0) {
      return new Pb2(value0);
    };
    return Pb2;
  }();
  var Pl = /* @__PURE__ */ function() {
    function Pl2(value0) {
      this.value0 = value0;
    }
    ;
    Pl2.create = function(value0) {
      return new Pl2(value0);
    };
    return Pl2;
  }();
  var HighContrast = /* @__PURE__ */ function() {
    function HighContrast2() {
    }
    ;
    HighContrast2.value = new HighContrast2();
    return HighContrast2;
  }();
  var Color = /* @__PURE__ */ function() {
    function Color2(value0) {
      this.value0 = value0;
    }
    ;
    Color2.create = function(value0) {
      return new Color2(value0);
    };
    return Color2;
  }();
  var Radius = /* @__PURE__ */ function() {
    function Radius2(value0) {
      this.value0 = value0;
    }
    ;
    Radius2.create = function(value0) {
      return new Radius2(value0);
    };
    return Radius2;
  }();
  var DataAttr = /* @__PURE__ */ function() {
    function DataAttr2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    DataAttr2.create = function(value0) {
      return function(value1) {
        return new DataAttr2(value0, value1);
      };
    };
    return DataAttr2;
  }();
  var RawAttr = /* @__PURE__ */ function() {
    function RawAttr2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    RawAttr2.create = function(value0) {
      return function(value1) {
        return new RawAttr2(value0, value1);
      };
    };
    return RawAttr2;
  }();
  var Width = /* @__PURE__ */ function() {
    function Width2(value0) {
      this.value0 = value0;
    }
    ;
    Width2.create = function(value0) {
      return new Width2(value0);
    };
    return Width2;
  }();
  var Height = /* @__PURE__ */ function() {
    function Height2(value0) {
      this.value0 = value0;
    }
    ;
    Height2.create = function(value0) {
      return new Height2(value0);
    };
    return Height2;
  }();
  var StyleProp = /* @__PURE__ */ function() {
    function StyleProp2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    StyleProp2.create = function(value0) {
      return function(value1) {
        return new StyleProp2(value0, value1);
      };
    };
    return StyleProp2;
  }();
  var step3 = function(a2) {
    var sty = function(k) {
      return function(v) {
        return {
          axes: a2.axes,
          dataAttrs: a2.dataAttrs,
          free: a2.free,
          rawAttrs: a2.rawAttrs,
          styles: insert5(k)(v)(a2.styles)
        };
      };
    };
    var dataA = function(k) {
      return function(v) {
        return {
          axes: a2.axes,
          free: a2.free,
          rawAttrs: a2.rawAttrs,
          styles: a2.styles,
          dataAttrs: insert5(k)(v)(a2.dataAttrs)
        };
      };
    };
    var axis = function(k) {
      return function(cls) {
        return {
          dataAttrs: a2.dataAttrs,
          free: a2.free,
          rawAttrs: a2.rawAttrs,
          styles: a2.styles,
          axes: insert5(k)(cls)(a2.axes)
        };
      };
    };
    var alignContentValue = function(v) {
      if (v === "between") {
        return "space-between";
      }
      ;
      if (v === "around") {
        return "space-around";
      }
      ;
      if (v === "evenly") {
        return "space-evenly";
      }
      ;
      return v;
    };
    return function(v) {
      if (v instanceof Class) {
        return {
          axes: a2.axes,
          dataAttrs: a2.dataAttrs,
          rawAttrs: a2.rawAttrs,
          styles: a2.styles,
          free: append5(a2.free)([v.value0])
        };
      }
      ;
      if (v instanceof Size) {
        return axis("size")("rt-r-size-" + v.value0);
      }
      ;
      if (v instanceof Variant) {
        return axis("variant")("rt-variant-" + v.value0);
      }
      ;
      if (v instanceof Weight) {
        return axis("weight")("rt-r-weight-" + v.value0);
      }
      ;
      if (v instanceof Trim) {
        return axis("trim")("rt-r-lt-" + v.value0);
      }
      ;
      if (v instanceof Display) {
        return axis("display")("rt-r-display-" + v.value0);
      }
      ;
      if (v instanceof Direction) {
        return axis("fd")("rt-r-fd-" + v.value0);
      }
      ;
      if (v instanceof Align) {
        return axis("ai")("rt-r-ai-" + v.value0);
      }
      ;
      if (v instanceof Justify) {
        return axis("jc")("rt-r-jc-" + function() {
          var $28 = v.value0 === "between";
          if ($28) {
            return "space-between";
          }
          ;
          return v.value0;
        }());
      }
      ;
      if (v instanceof Wrap) {
        return axis("fw")("rt-r-fw-" + v.value0);
      }
      ;
      if (v instanceof Gap) {
        return axis("gap")("rt-r-gap-" + v.value0);
      }
      ;
      if (v instanceof Position) {
        return axis("position")("rt-r-position-" + v.value0);
      }
      ;
      if (v instanceof Columns) {
        return axis("gtc")("rt-r-gtc-" + v.value0);
      }
      ;
      if (v instanceof Rows) {
        return axis("gtr")("rt-r-gtr-" + v.value0);
      }
      ;
      if (v instanceof Flow) {
        return axis("gaf")("rt-r-gaf-" + v.value0);
      }
      ;
      if (v instanceof AlignContent) {
        return axis("ac")("rt-r-ac-" + alignContentValue(v.value0));
      }
      ;
      if (v instanceof JustifyItems) {
        return axis("ji")("rt-r-ji-" + v.value0);
      }
      ;
      if (v instanceof Side) {
        return axis("side")("rt-r-side-" + v.value0);
      }
      ;
      if (v instanceof Clip) {
        return axis("clip")("rt-r-clip-" + v.value0);
      }
      ;
      if (v instanceof M) {
        return axis("m")("rt-r-m-" + v.value0);
      }
      ;
      if (v instanceof Mx) {
        return axis("mx")("rt-r-mx-" + v.value0);
      }
      ;
      if (v instanceof My) {
        return axis("my")("rt-r-my-" + v.value0);
      }
      ;
      if (v instanceof Mt) {
        return axis("mt")("rt-r-mt-" + v.value0);
      }
      ;
      if (v instanceof Mr) {
        return axis("mr")("rt-r-mr-" + v.value0);
      }
      ;
      if (v instanceof Mb) {
        return axis("mb")("rt-r-mb-" + v.value0);
      }
      ;
      if (v instanceof Ml) {
        return axis("ml")("rt-r-ml-" + v.value0);
      }
      ;
      if (v instanceof P) {
        return axis("p")("rt-r-p-" + v.value0);
      }
      ;
      if (v instanceof Px) {
        return axis("px")("rt-r-px-" + v.value0);
      }
      ;
      if (v instanceof Py) {
        return axis("py")("rt-r-py-" + v.value0);
      }
      ;
      if (v instanceof Pt) {
        return axis("pt")("rt-r-pt-" + v.value0);
      }
      ;
      if (v instanceof Pr) {
        return axis("pr")("rt-r-pr-" + v.value0);
      }
      ;
      if (v instanceof Pb) {
        return axis("pb")("rt-r-pb-" + v.value0);
      }
      ;
      if (v instanceof Pl) {
        return axis("pl")("rt-r-pl-" + v.value0);
      }
      ;
      if (v instanceof HighContrast) {
        return axis("hc")("rt-high-contrast");
      }
      ;
      if (v instanceof Color) {
        return dataA("accent-color")(v.value0);
      }
      ;
      if (v instanceof Radius) {
        return dataA("radius")(v.value0);
      }
      ;
      if (v instanceof DataAttr) {
        return dataA(v.value0)(v.value1);
      }
      ;
      if (v instanceof RawAttr) {
        return {
          axes: a2.axes,
          free: a2.free,
          dataAttrs: a2.dataAttrs,
          styles: a2.styles,
          rawAttrs: insert5(v.value0)(v.value1)(a2.rawAttrs)
        };
      }
      ;
      if (v instanceof Width) {
        return sty("width")(v.value0);
      }
      ;
      if (v instanceof Height) {
        return sty("height")(v.value0);
      }
      ;
      if (v instanceof StyleProp) {
        return sty(v.value0)(v.value1);
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Themes.Prop (line 97, column 10 - line 146, column 27): " + [v.constructor.name]);
    };
  };
  var attrs = function(base2) {
    return function(props) {
      var mkRaw = function(v) {
        return attr2(v.value0)(v.value1);
      };
      var mkData = function(v) {
        return attr2("data-" + v.value0)(v.value1);
      };
      var a2 = foldl4(step3)({
        axes: empty2,
        free: base2,
        dataAttrs: empty2,
        rawAttrs: empty2,
        styles: empty2
      })(props);
      var classTokens = filter(function(v) {
        return v !== "";
      })(append5(a2.free)(map34(snd)(toUnfoldable3(a2.axes))));
      var classAttr = [class_(joinWith(" ")(classTokens))];
      var dataList = toUnfoldable3(a2.dataAttrs);
      var rawList = toUnfoldable3(a2.rawAttrs);
      var styleList = toUnfoldable3(a2.styles);
      var styleAttr = function() {
        var $70 = $$null(styleList);
        if ($70) {
          return [];
        }
        ;
        return [style(joinWith(" ")(map34(function(v) {
          return v.value0 + (": " + (v.value1 + ";"));
        })(styleList)))];
      }();
      return append5(classAttr)(append5(styleAttr)(append5(map34(mkData)(dataList))(map34(mkRaw)(rawList))));
    };
  };
  var el = function(tag) {
    return function(base2) {
      return function(props) {
        return function(children2) {
          return element2(tag)(attrs(base2)(props))(children2);
        };
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Themes.Button/index.js
  var append6 = /* @__PURE__ */ append(semigroupArray);
  var button3 = function(props) {
    return el("button")(["rt-reset", "rt-BaseButton", "rt-Button"])(append6([new Variant("solid"), new Size("2"), new Color(""), new RawAttr("type", "button")])(props));
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Themes.Layout/index.js
  var flex = /* @__PURE__ */ el("div")(["rt-Flex"]);
  var box = /* @__PURE__ */ el("div")(["rt-Box"]);

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Themes.TextArea/index.js
  var append7 = /* @__PURE__ */ append(semigroupArray);
  var textArea = function(placeholder4) {
    return function(props) {
      return div3(attrs(["rt-TextAreaRoot"])(append7([new Size("2"), new Variant("surface")])(props)))([textarea([class_("rt-reset rt-TextAreaInput"), placeholder3(placeholder4)])]);
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Themes.TextField/index.js
  var append8 = /* @__PURE__ */ append(semigroupArray);
  var textFieldValue = function(placeholder4) {
    return function(value12) {
      return function(props) {
        return div3(attrs(["rt-TextFieldRoot"])(append8([new Size("2"), new Variant("surface")])(props)))([input([class_("rt-reset rt-TextFieldInput"), spellcheck2(false), placeholder3(placeholder4), attr2("value")(value12)])]);
      };
    };
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/Hydrogen.Themes.Typography/index.js
  var textAs = function(tag) {
    return el(tag)(["rt-Text"]);
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/output/ThemesInteractive.Main/index.js
  var append9 = /* @__PURE__ */ append(semigroupArray);
  var map35 = /* @__PURE__ */ map(functorArray);
  var bind24 = /* @__PURE__ */ bind(bindEffect);
  var slot_2 = /* @__PURE__ */ slot_();
  var slot_1 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "dialog";
    }
  })(ordUnit);
  var component9 = /* @__PURE__ */ component3(monadEffectAff);
  var slot_22 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "alertdialog";
    }
  })(ordUnit);
  var component1 = /* @__PURE__ */ component(monadEffectAff);
  var slot_3 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "popover";
    }
  })(ordUnit);
  var component22 = /* @__PURE__ */ component6(monadEffectAff);
  var slot_4 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "tooltip";
    }
  })(ordUnit);
  var component32 = /* @__PURE__ */ component8(monadEffectAff);
  var slot_5 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "hovercard";
    }
  })(ordUnit);
  var component42 = /* @__PURE__ */ component5(monadEffectAff);
  var slot_6 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "dropdownmenu";
    }
  })(ordUnit);
  var component52 = /* @__PURE__ */ component4(monadEffectAff);
  var slot_7 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "contextmenu";
    }
  })(ordUnit);
  var component62 = /* @__PURE__ */ component2(monadEffectAff);
  var slot_8 = /* @__PURE__ */ slot_2({
    reflectSymbol: function() {
      return "select";
    }
  })(ordUnit);
  var component72 = /* @__PURE__ */ component7(monadEffectAff);
  var discard18 = /* @__PURE__ */ discard(discardUnit)(bindAff);
  var bind114 = /* @__PURE__ */ bind(bindAff);
  var for_16 = /* @__PURE__ */ for_(applicativeAff)(foldableMaybe);
  var $$void11 = /* @__PURE__ */ $$void(functorAff);
  var tooltipStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"),
    content: /* @__PURE__ */ cn("light radix-themes rt-TooltipContent rt-r-max-w")
  };
  var themeDataAttrs = function(isRoot) {
    return [dataAttr("accent-color")("indigo"), dataAttr("gray-color")("slate"), dataAttr("has-background")(function() {
      if (isRoot) {
        return "true";
      }
      ;
      return "false";
    }()), dataAttr("is-root-theme")(function() {
      if (isRoot) {
        return "true";
      }
      ;
      return "false";
    }()), dataAttr("panel-background")("translucent"), dataAttr("radius")("medium"), dataAttr("scaling")("100%")];
  };
  var svgNS = "http://www.w3.org/2000/svg";
  var tooltipArrow = /* @__PURE__ */ elementNS(svgNS)("svg")([/* @__PURE__ */ attr2("class")("rt-TooltipArrow"), /* @__PURE__ */ attr2("width")("10"), /* @__PURE__ */ attr2("height")("5"), /* @__PURE__ */ attr2("viewBox")("0 0 30 10"), /* @__PURE__ */ attr2("preserveAspectRatio")("none"), /* @__PURE__ */ attr2("style")("display: block;")])([/* @__PURE__ */ elementNS(svgNS)("polygon")([/* @__PURE__ */ attr2("points")("0,0 30,0 15,10")])([])]);
  var splitOn = function(sep) {
    return function(s) {
      var v = indexOf2(sep)(s);
      if (v instanceof Nothing) {
        return [s];
      }
      ;
      if (v instanceof Just) {
        var kv = splitAt2(v.value0)(s);
        return append9([kv.before])(splitOn(sep)(drop2(1)(kv.after)));
      }
      ;
      throw new Error("Failed pattern match at ThemesInteractive.Main (line 511, column 17 - line 513, column 91): " + [v.constructor.name]);
    };
  };
  var selectStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-SelectTrigger rt-r-size-2 rt-variant-surface"),
    value: /* @__PURE__ */ cn("rt-SelectTriggerInner"),
    content: /* @__PURE__ */ cn("light radix-themes rt-SelectContent rt-r-size-2 rt-variant-solid"),
    scrollRoot: /* @__PURE__ */ cn("rt-ScrollAreaRoot"),
    scrollViewport: /* @__PURE__ */ cn("rt-ScrollAreaViewport rt-SelectViewport"),
    group: /* @__PURE__ */ cn("rt-SelectGroup"),
    label: /* @__PURE__ */ cn("rt-SelectLabel"),
    item: /* @__PURE__ */ cn("rt-SelectItem"),
    indicator: /* @__PURE__ */ cn("rt-SelectItemIndicator")
  };
  var portalThemeAttrs = /* @__PURE__ */ function() {
    return [new Tuple("accent-color", "indigo"), new Tuple("gray-color", "slate"), new Tuple("has-background", "false"), new Tuple("is-root-theme", "false"), new Tuple("panel-background", "translucent"), new Tuple("radius", "medium"), new Tuple("scaling", "100%")];
  }();
  var popperContentVars = function(c) {
    return "--radix-" + (c + ("-content-transform-origin: var(--radix-popper-transform-origin); " + ("--radix-" + (c + ("-content-available-width: var(--radix-popper-available-width); " + ("--radix-" + (c + ("-content-available-height: var(--radix-popper-available-height); " + ("--radix-" + (c + ("-trigger-width: var(--radix-popper-anchor-width); " + ("--radix-" + (c + "-trigger-height: var(--radix-popper-anchor-height);")))))))))))));
  };
  var tooltipInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput8.open,
      defaultOpen: defaultInput8.defaultOpen,
      side: defaultInput8.side,
      align: defaultInput8.align,
      style: tooltipStyle,
      offset: 8,
      padding: 10,
      triggerAttrs: [new Tuple("accent-color", "")],
      portalAttrs: portalThemeAttrs,
      contentStyle: "--max-width: 9999px; " + popperContentVars("tooltip"),
      trigger: [text5("Hover me")],
      content: [textAs("p")([new Size("1"), new Class("rt-TooltipText")])([text5("Add to library")])],
      arrow: [tooltipArrow]
    };
  }();
  var popoverStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"),
    content: /* @__PURE__ */ cn("light radix-themes rt-PopoverContent rt-PopperContent rt-r-max-w rt-r-size-2 rt-r-w")
  };
  var popoverInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput6.open,
      defaultOpen: defaultInput6.defaultOpen,
      side: defaultInput6.side,
      offset: defaultInput6.offset,
      padding: defaultInput6.padding,
      align: Start.value,
      style: popoverStyle,
      triggerAttrs: [new Tuple("accent-color", "")],
      portalAttrs: portalThemeAttrs,
      contentStyle: "--width: 360px; --max-width: 9999px; " + popperContentVars("popover"),
      trigger: [text5("Comment")],
      content: [flex([new Gap("3")])([box([new Class("rt-r-fg-1")])([textArea("Write a comment\u2026")([new Height("80px")])])])]
    };
  }();
  var menuStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"),
    content: /* @__PURE__ */ cn("light radix-themes rt-BaseMenuContent rt-DropdownMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"),
    scrollRoot: /* @__PURE__ */ cn("rt-ScrollAreaRoot"),
    scrollViewport: /* @__PURE__ */ cn("rt-ScrollAreaViewport"),
    menuViewport: /* @__PURE__ */ cn("rt-BaseMenuViewport rt-DropdownMenuViewport"),
    focusRing: /* @__PURE__ */ cn("rt-ScrollAreaViewportFocusRing"),
    item: /* @__PURE__ */ cn("rt-BaseMenuItem rt-DropdownMenuItem rt-reset"),
    shortcut: /* @__PURE__ */ cn("rt-BaseMenuShortcut rt-DropdownMenuShortcut"),
    separator: /* @__PURE__ */ cn("rt-BaseMenuSeparator rt-DropdownMenuSeparator")
  };
  var menuRow = function(value12) {
    return function(label5) {
      return function(shortcut) {
        return function(accent) {
          return new MenuItemEntry2({
            value: value12,
            label: [text5(label5)],
            shortcut: [text5(shortcut)],
            accent,
            disabled: false
          });
        };
      };
    };
  };
  var hoverCardStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-Text rt-Link rt-HoverCardTrigger rt-underline-auto"),
    content: /* @__PURE__ */ cn("light radix-themes rt-HoverCardContent rt-PopperContent rt-r-max-w rt-r-size-2")
  };
  var hoverCardInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput5.open,
      defaultOpen: defaultInput5.defaultOpen,
      side: defaultInput5.side,
      offset: defaultInput5.offset,
      padding: defaultInput5.padding,
      triggerHref: defaultInput5.triggerHref,
      align: Start.value,
      style: hoverCardStyle,
      triggerAttrs: [new Tuple("accent-color", "")],
      portalAttrs: portalThemeAttrs,
      contentStyle: "--max-width: 9999px; " + popperContentVars("hover-card"),
      wrapperClass: cn("rt-Text"),
      proseBefore: [text5("Follow ")],
      proseAfter: [text5(" for updates.")],
      trigger: [text5("@radix_ui")],
      content: [textAs("div")([new Size("1"), new Color("gray")])([text5("The design system for building modern web applications.")])]
    };
  }();
  var firstJust = /* @__PURE__ */ function() {
    var isJust2 = function(v) {
      if (v instanceof Just) {
        return true;
      }
      ;
      if (v instanceof Nothing) {
        return false;
      }
      ;
      throw new Error("Failed pattern match at ThemesInteractive.Main (line 522, column 12 - line 524, column 21): " + [v.constructor.name]);
    };
    return function(v) {
      if (v.length === 0) {
        return Nothing.value;
      }
      ;
      var v1 = find2(isJust2)(v);
      if (v1 instanceof Just && v1.value0 instanceof Just) {
        return new Just(v1.value0.value0);
      }
      ;
      return Nothing.value;
    };
  }();
  var lookupParam = function(key2) {
    return function(search2) {
      var match = function(p2) {
        var v = indexOf2("=")(p2);
        if (v instanceof Just) {
          var kv = splitAt2(v.value0)(p2);
          var $69 = kv.before === key2;
          if ($69) {
            return new Just(drop2(1)(kv.after));
          }
          ;
          return Nothing.value;
        }
        ;
        if (v instanceof Nothing) {
          return Nothing.value;
        }
        ;
        throw new Error("Failed pattern match at ThemesInteractive.Main (line 504, column 15 - line 506, column 25): " + [v.constructor.name]);
      };
      var body3 = drop2(1)(search2);
      var pairs = splitOn("&")(body3);
      return fromMaybe("")(firstJust(map35(match)(pairs)));
    };
  };
  var queryParam = function(key2) {
    return function __do12() {
      var search2 = bind24(bind24(windowImpl)(location))(search)();
      return lookupParam(key2)(search2);
    };
  };
  var dialogStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-solid"),
    overlay: /* @__PURE__ */ cn("light radix-themes rt-BaseDialogOverlay rt-DialogOverlay"),
    scroll: /* @__PURE__ */ cn("rt-BaseDialogScroll rt-DialogScroll"),
    scrollPadding: /* @__PURE__ */ cn("rt-BaseDialogScrollPadding rt-DialogScrollPadding rt-r-align-center"),
    content: /* @__PURE__ */ cn("rt-BaseDialogContent rt-DialogContent rt-r-max-w rt-r-size-3"),
    title: /* @__PURE__ */ cn("rt-Heading rt-r-lt-start rt-r-size-5 rt-r-mb-3"),
    description: /* @__PURE__ */ cn("rt-Text rt-r-size-2 rt-r-mb-4")
  };
  var dialogInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput3.open,
      defaultOpen: defaultInput3.defaultOpen,
      modal: defaultInput3.modal,
      closeOnEscape: defaultInput3.closeOnEscape,
      closeOnOutsideClick: defaultInput3.closeOnOutsideClick,
      style: dialogStyle,
      triggerAttrs: [new Tuple("accent-color", "")],
      portalAttrs: portalThemeAttrs,
      contentStyle: "--max-width: 450px; pointer-events: auto;",
      trigger: [text5("Edit profile")],
      title: [text5("Edit profile")],
      description: [text5("Make changes to your profile.")],
      content: [flex([new Direction("column"), new Gap("3")])([label_([textAs("div")([new Size("2"), new Mb("1"), new Weight("bold")])([text5("Name")]), textFieldValue("Enter your full name")("Freja Johnsen")([])])]), flex([new Gap("3"), new Mt("4"), new Justify("end")])([button3([new Variant("soft"), new Color("gray")])([text5("Cancel")]), button3([])([text5("Save")])])]
    };
  }();
  var ctxRow = function(value12) {
    return function(label5) {
      return function(shortcut) {
        return function(accent) {
          return new MenuItemEntry({
            value: value12,
            label: [text5(label5)],
            shortcut: [text5(shortcut)],
            accent,
            disabled: false
          });
        };
      };
    };
  };
  var contextMenuStyle = {
    trigger: /* @__PURE__ */ cn("rt-Flex rt-r-ai-center rt-r-jc-center"),
    content: /* @__PURE__ */ cn("light radix-themes rt-BaseMenuContent rt-ContextMenuContent rt-PopperContent rt-r-size-2 rt-variant-solid"),
    scrollRoot: /* @__PURE__ */ cn("rt-ScrollAreaRoot"),
    scrollViewport: /* @__PURE__ */ cn("rt-ScrollAreaViewport"),
    menuViewport: /* @__PURE__ */ cn("rt-BaseMenuViewport rt-ContextMenuViewport"),
    focusRing: /* @__PURE__ */ cn("rt-ScrollAreaViewportFocusRing"),
    item: /* @__PURE__ */ cn("rt-BaseMenuItem rt-ContextMenuItem rt-reset"),
    shortcut: /* @__PURE__ */ cn("rt-BaseMenuShortcut rt-ContextMenuShortcut"),
    separator: /* @__PURE__ */ cn("rt-BaseMenuSeparator rt-ContextMenuSeparator")
  };
  var contextMenuInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput2.open,
      defaultOpen: defaultInput2.defaultOpen,
      align: defaultInput2.align,
      offset: defaultInput2.offset,
      padding: defaultInput2.padding,
      idPrefix: defaultInput2.idPrefix,
      side: Right2.value,
      style: contextMenuStyle,
      portalAttrs: portalThemeAttrs,
      contentStyle: "outline: none; " + (popperContentVars("context-menu") + " pointer-events: auto;"),
      triggerStyle: "width: 240px; height: 120px; border: 1px dashed var(--gray-6); border-radius: var(--radius-3);",
      trigger: [textAs("span")([new Size("2"), new Color("gray")])([text5("Right-click here")])],
      entries: [ctxRow("edit")("Edit")("\u2318 E")(""), ctxRow("duplicate")("Duplicate")("\u2318 D")(""), menuSeparator, ctxRow("delete")("Delete")("\u2318 \u232B")("red")]
    };
  }();
  var chevronCls = function(klass) {
    return elementNS(svgNS)("svg")(append9(function() {
      var $71 = klass === "";
      if ($71) {
        return [];
      }
      ;
      return [attr2("class")(klass), attr2("aria-hidden")("true")];
    }())([attr2("width")("9"), attr2("height")("9"), attr2("viewBox")("0 0 9 9"), attr2("fill")("currentcolor"), attr2("xmlns")("http://www.w3.org/2000/svg")]))([elementNS(svgNS)("path")([attr2("d")("M0.135232 3.15803C0.324102 2.95657 0.640521 2.94637 0.841971 3.13523L4.5 6.56464L8.158 3.13523C8.3595 2.94637 8.6759 2.95657 8.8648 3.15803C9.0536 3.35949 9.0434 3.67591 8.842 3.86477L4.84197 7.6148C4.64964 7.7951 4.35036 7.7951 4.15803 7.6148L0.158031 3.86477C-0.0434285 3.67591 -0.0536285 3.35949 0.135232 3.15803Z")])([])]);
  };
  var chevron = /* @__PURE__ */ chevronCls("");
  var dropdownMenuInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput4.open,
      defaultOpen: defaultInput4.defaultOpen,
      side: defaultInput4.side,
      align: defaultInput4.align,
      offset: defaultInput4.offset,
      padding: defaultInput4.padding,
      idPrefix: defaultInput4.idPrefix,
      style: menuStyle,
      triggerAttrs: [new Tuple("accent-color", "")],
      portalAttrs: portalThemeAttrs,
      contentStyle: "outline: none; " + (popperContentVars("dropdown-menu") + " pointer-events: auto;"),
      trigger: [text5("Options"), chevron],
      entries: [menuRow("edit")("Edit")("\u2318 E")(""), menuRow("duplicate")("Duplicate")("\u2318 D")(""), menuSeparator2, menuRow("archive")("Archive")("\u2318 N")(""), menuSeparator2, menuRow("delete")("Delete")("\u2318 \u232B")("red")]
    };
  }();
  var checkSvg = /* @__PURE__ */ elementNS(svgNS)("svg")([/* @__PURE__ */ attr2("class")("rt-SelectItemIndicatorIcon"), /* @__PURE__ */ attr2("width")("9"), /* @__PURE__ */ attr2("height")("9"), /* @__PURE__ */ attr2("viewBox")("0 0 9 9"), /* @__PURE__ */ attr2("fill")("currentcolor"), /* @__PURE__ */ attr2("xmlns")("http://www.w3.org/2000/svg")])([/* @__PURE__ */ elementNS(svgNS)("path")([/* @__PURE__ */ attr2("fill-rule")("evenodd"), /* @__PURE__ */ attr2("clip-rule")("evenodd"), /* @__PURE__ */ attr2("d")("M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z")])([])]);
  var selectInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput7.open,
      defaultOpen: defaultInput7.defaultOpen,
      value: defaultInput7.value,
      offset: defaultInput7.offset,
      padding: defaultInput7.padding,
      idPrefix: defaultInput7.idPrefix,
      defaultValue: "apple",
      style: selectStyle,
      portalAttrs: portalThemeAttrs,
      contentStyle: "box-sizing: border-box; max-height: 100%; display: flex; flex-direction: column; outline: none; pointer-events: auto;",
      trigger: [chevronCls("rt-SelectIcon")],
      groupLabel: [text5("Fruits")],
      checkIcon: [checkSvg],
      items: [{
        value: "apple",
        label: [text5("Apple")],
        disabled: false
      }, {
        value: "orange",
        label: [text5("Orange")],
        disabled: false
      }, {
        value: "grape",
        label: [text5("Grape")],
        disabled: false
      }]
    };
  }();
  var alertDialogStyle = {
    trigger: /* @__PURE__ */ cn("rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-solid"),
    overlay: /* @__PURE__ */ cn("light radix-themes rt-BaseDialogOverlay rt-AlertDialogOverlay"),
    scroll: /* @__PURE__ */ cn("rt-BaseDialogScroll rt-AlertDialogScroll"),
    scrollPadding: /* @__PURE__ */ cn("rt-BaseDialogScrollPadding rt-AlertDialogScrollPadding rt-r-align-center"),
    content: /* @__PURE__ */ cn("rt-BaseDialogContent rt-AlertDialogContent rt-r-max-w rt-r-size-3"),
    title: /* @__PURE__ */ cn("rt-Heading rt-r-lt-start rt-r-mb-3 rt-r-size-5"),
    description: /* @__PURE__ */ cn("rt-Text rt-r-size-2")
  };
  var alertDialogInput = /* @__PURE__ */ function() {
    return {
      open: defaultInput.open,
      defaultOpen: defaultInput.defaultOpen,
      closeOnEscape: defaultInput.closeOnEscape,
      style: alertDialogStyle,
      triggerAttrs: [new Tuple("accent-color", "red")],
      portalAttrs: portalThemeAttrs,
      contentStyle: "--max-width: 450px; pointer-events: auto;",
      trigger: [text5("Revoke access")],
      title: [text5("Revoke access")],
      description: [text5("Are you sure? This application will no longer be accessible.")],
      content: [flex([new Gap("3"), new Mt("4"), new Justify("end")])([button3([new Variant("soft"), new Color("gray")])([text5("Cancel")]), button3([new Color("red")])([text5("Revoke access")])])]
    };
  }();
  var _tooltip = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _select = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _popover = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _hovercard = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _dropdownmenu = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _dialog = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _contextmenu = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var _alertdialog = /* @__PURE__ */ function() {
    return $$Proxy.value;
  }();
  var view = function(c) {
    return div3(append9([class_("radix-themes light"), style("--default-font-family: 'Inter Variable', sans-serif;")])(themeDataAttrs(true)))([box([new P("6")])([function() {
      if (c === "dialog") {
        return slot_1(_dialog)(unit)(component9)(dialogInput);
      }
      ;
      if (c === "alertdialog") {
        return slot_22(_alertdialog)(unit)(component1)(alertDialogInput);
      }
      ;
      if (c === "popover") {
        return slot_3(_popover)(unit)(component22)(popoverInput);
      }
      ;
      if (c === "tooltip") {
        return slot_4(_tooltip)(unit)(component32)(tooltipInput);
      }
      ;
      if (c === "hovercard") {
        return slot_5(_hovercard)(unit)(component42)(hoverCardInput);
      }
      ;
      if (c === "dropdownmenu") {
        return slot_6(_dropdownmenu)(unit)(component52)(dropdownMenuInput);
      }
      ;
      if (c === "contextmenu") {
        return slot_7(_contextmenu)(unit)(component62)(contextMenuInput);
      }
      ;
      if (c === "select") {
        return slot_8(_select)(unit)(component72)(selectInput);
      }
      ;
      return div_([text5("pick a ?c=<component> (e.g. ?c=dialog)")]);
    }()])]);
  };
  var root = function(c) {
    return mkComponent({
      initialState: $$const(unit),
      render: $$const(view(c)),
      "eval": mkEval(defaultEval)
    });
  };
  var main2 = function __do11() {
    var c = queryParam("c")();
    return runHalogenAff(discard18(awaitLoad)(function() {
      return bind114(selectElement("#root"))(function(mEl) {
        return for_16(mEl)(function(el2) {
          return $$void11(runUI2(root(c))(unit)(el2));
        });
      });
    }))();
  };

  // buck-out/v2/gen/root/acdb73369f2e5aa5/examples/themes-interactive/__app__/app-dist/entry.mjs
  main2();
})();
