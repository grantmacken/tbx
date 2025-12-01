# runtimes

```
podman pull ghcr.io/grantmacken/tbx-runtimes:latest
toolbox list --containers
toolbox rm runtimes -f || true
toolbox create --image ghcr.io/grantmacken/tbx-runtimes:latest runtimes
toolbox enter runtimes
```

The runtimes container provides runtimes for various programming languages.

## The beam and associated language and tooling

Included in this toolbox are the latest releases of the Erlang, Elixir and Gleam programming languages.
The Erlang programming language is a general-purpose, concurrent, functional programming language
and **runtime** system. It is used to build massively scalable soft real-time systems with high availability.
The BEAM is the virtual machine at the core of the Erlang Open Telecom Platform (OTP).
The included Elixir and Gleam programming languages also run on the BEAM.
BEAM tooling included is the latest versions of the Rebar3 and the Mix build tools.
The gleam programming language is also included.
Gleam is a statically typed language for building scalable and maintainable applications.
It compiles to efficient Erlang code that runs on the BEAM virtual machine.
It can also can compile to JavaScript for building web applications.
Which is why we also include Nodejs in this toolbox.

## nodejs
Also included in this toolbox is the nodejs runtime and associated tooling.
Nodejs is a JavaScript runtime built on Chrome's V8 JavaScript engine.
Included is the latest version of Nodejs along with the npm package manager.

## Python runtime and tooling
Python is is already included in the Fedora base image.
We add the uv package manager for Python.
The uv package manager is a fast dependency resolver and package manager for Python.
It is designed to be a modern alternative to pip and poetry.

