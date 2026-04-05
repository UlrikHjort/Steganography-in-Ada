# steg - Ada PNG Steganography

**[Steganography](https://en.wikipedia.org/wiki/Steganography)**, Hide and recover a text message inside a PNG image using the
**Least Significant Bit (LSB)** technique.

Written in **Ada 2012** with a thin C wrapper around **libpng**.

---

## How it works

Each pixel in an PNG image has three 8-bit colour channels: R, G, B.
Changing the least significant bit of a channel shifts its value by at most 1,
a difference that is completely invisible to the human eye.

`steg` uses one LSB per channel, giving **3 hidden bits per pixel**:

```
Pixel (x, y)
  R: 11001010  ->  11001010   (bit 0 of the message)
  G: 01110111  ->  01110111   (bit 1)
  B: 10110100  ->  10110101   (bit 2)
```

The pixel data is visited in row-major order (left->right, top->bottom).
The first 32 bits (4 bytes, little-endian) encode the mesage length;
the remaining bits carry the message payload, LSB of each byte first.

### Capacity

| Image size | Hidden capacity |
|------------|----------------|
| 200 * 200  | ~14 KB |
| 800 * 600  | ~175 KB |
| 1920 * 1080 | ~760 KB |

Formula: `floor(width * height  3 / 8) - 4 bytes`

---

## Dependencies

| Dependency | Purpose |
|------------|---------|
| GNAT (GCC Ada) | Ada compiler |
| GPRbuild | build tool |
| libpng + zlib | PNG read/write (via C wrapper) |


```bash
sudo apt install gnat gprbuild libpng-dev
```

---

## Building

```bash
make
```

The Makefile generate the GPRbuild compiler
config (`steg.cgpr`) and compiling the project. The `steg` binary is placed in
the project root.

### All make targets

| Target | Description |
|--------|-------------|
| `make` | Configure (if needed) and build |
| `make config` | Generate `steg.cgpr` only |
| `make build` | Compile and link |
| `make clean` | Remove object files and binary |
| `make distclean` | Clean + remove `steg.cgpr` |
| `make help` | Print available targets |

---

## Usage

### Encode - hide a message

```bash
./steg encode <input.png> <output.png> <message>
```

Example:

```
$ ./steg encode photo.png secret.png "Meet me at midnight."
Image    : photo.png ( 800 * 600 px)
Capacity : 179996 bytes
Message  : 20 bytes
Done  -> secret.png
```

`output.png` is visually identical to `input.png` but carries the hidden text.

### Decode - reveal a message

```bash
./steg decode <input.png>
```

Example:

```
$ ./steg decode secret.png
Hidden message: "Meet me at midnight."

$ ./steg decode photo.png
No hidden message found in photo.png.
```

---

## Notes

- **PNG only.** JPEG uses lossy compression that destroy hidden bits on
  re-save; PNG is lossless and safe.
- Images are always normalised to **8-bit RGB** on load (alpha stripped,
  palette expanded, 16-bit depth reduced).
- Message longer than the image capacity are rejected with an error.
- An image with no encoded message (or an unrecognised length header)
  returns an empty result - no crash.
