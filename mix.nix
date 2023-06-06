{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0ha6vmf5p3xlbf5w1msa89frhvfk535rnyfybz9wdmh6vdms8v96";
      };

      beamDeps = [];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.10.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0sqxqjdykxc2ai9cvkc0xjwkvr80z98wzlqlrd1z3iiw32vwrz9s";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowboy_telemetry = buildRebar3 rec {
      name = "cowboy_telemetry";
      version = "0.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1pn90is3k9dq64wbijvzkqb6ldfqvwiqi7ymc8dx6ra5xv0vm63x";
      };

      beamDeps = [ cowboy telemetry ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.12.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1c4dgi8canscyjgddp22mjc69znvwy44wk3r7jrl2wvs6vv76fqn";
      };

      beamDeps = [];
    };

    dialyxir = buildMix rec {
      name = "dialyxir";
      version = "1.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0vv90jip2w362n3l7dkhqfdwlz97nwji535kn3fbk3dassya9ch0";
      };

      beamDeps = [ erlex ];
    };

    enough = buildRebar3 rec {
      name = "enough";
      version = "0.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "18gr9cvjar9rrmcj0crgwjb4np4adfbwcaxijajhwpjzvamwfq04";
      };

      beamDeps = [];
    };

    erlex = buildMix rec {
      name = "erlex";
      version = "0.2.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0x8c1j62y748ldvlh46sxzv5514rpzm809vxn594vd7y25by5lif";
      };

      beamDeps = [];
    };

    gen_state_machine = buildMix rec {
      name = "gen_state_machine";
      version = "3.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "05gdy0cxsmg3j43xmd6vm3nzsi8vlk94kdzn15rypg5yfhjnan8a";
      };

      beamDeps = [];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.18.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "13hja14kig5jnzcizpdghj68i88f0yd9wjdfjic9nzi98kzxmv54";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    httpoison = buildMix rec {
      name = "httpoison";
      version = "2.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "030n18hphjsafdz52gxj3hrsrj2s5ndjjmsgxxyq4hvb62s5qigw";
      };

      beamDeps = [ hackney ];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1sjcjibl34sprpf1dgdmzfww24xlyy34lpj7mhcys4j4i6vnwdwj";
      };

      beamDeps = [ unicode_util_compat ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0891p2yrg3ri04p302cxfww3fi16pvvw1kh4r91zg85jhl87k8vr";
      };

      beamDeps = [];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "05lz15piphyhvvm3d1ldjyw0zsrvz50d2m5f2q3s8x2gvkfrmc39";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0szzdfalafpawjrrwbrplhkgxjv8837mlxbkpbn5xlj4vgq0p8r7";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "08wkw73dy449n68ssrkz57gikfzqk3vfnf264s31jn5aa1b5hy7j";
      };

      beamDeps = [];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.3.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "12w8ai6b5s6b4hnvkav7hwxd846zdd74r32f84nkcmjzi1vrbk87";
      };

      beamDeps = [];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.14.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "04wdyv6nma74bj1m49vkm2bc5mjf8zclfg957fng8g71hw0wabw4";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.6.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "04v6xc4v741dr2y38j66fmcc4xc037dnaxzkj2vih6j53yif2dny";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "1.2.5";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0hnqgzc3zas7j7wycgnkkdhaji5farkqccy2n4p1gqj5ccfrlm16";
      };

      beamDeps = [];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1rfz5ld54pkd2w25jadyznia2vb7aw9bclck21fizargd39wzys9";
      };

      beamDeps = [];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1026l1z1jh25z8bfrhaw0ryk5gprhrpnirq877zqhg253x3x5c5x";
      };

      beamDeps = [];
    };

    systemd = buildRebar3 rec {
      name = "systemd";
      version = "0.6.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1f082zydhgif5p8pzj4ii32j9p93psgrmgy7ax8v06hch08vjqjh";
      };

      beamDeps = [ enough ];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1mgyx9zw92g6w8fp9pblm3b0bghwxwwcbslrixq23ipzisfwxnfs";
      };

      beamDeps = [];
    };

    tortoise311 = buildMix rec {
      name = "tortoise311";
      version = "0.11.5";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "19cbc9xwd2sc5scvmrlfadxg5kfzxfa4yr5k1q13kcfivz5ry9v1";
      };

      beamDeps = [ gen_state_machine telemetry ];
    };

    typed_struct = buildMix rec {
      name = "typed_struct";
      version = "0.3.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0v8v3l8j7g3ran3f9gc2nc1mkj6kwfdr6kshm2cf3r0zlv1xa2y5";
      };

      beamDeps = [];
    };

    tz = buildMix rec {
      name = "tz";
      version = "0.26.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0z7madh4cwnrw4rdmlsgp34dr683ldky2d7nlzm0vzcw3sjcwf6s";
      };

      beamDeps = [];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "08952lw8cjdw8w171lv8wqbrxc4rcmb3jhkrdb7n06gngpbfdvi5";
      };

      beamDeps = [];
    };
  };
in self

