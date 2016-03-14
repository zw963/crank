# Foreman.cr

Foreman in Crystal

This is very much a work in progress.

## Installation

Clone this repo

`git clone https://github.com/arktisklada/Foreman.cr`

Symlink `foreman` to `bin/foreman`

## Usage

With the following `Procfile`:

```
web: bin/server 7000
worker: bin/worker queue=FOO
```

Run `foreman`

```
17:12:48 web    | listening on port 7000
17:12:48 worker | listening to queue FOO
```

## Credits

Inspired by the original [Foreman](https://github.com/ddollar/foreman) by David Dollar (@ddollar).

## License

Apache 2.0 &copy; 2016 Clayton Liggitt