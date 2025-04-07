# Quirks

Documenting tool quirks.

## Questa

### 1 

Assigning `'{var:val, default: 'x}` to a `struct` containing `enum` types.

Message:

```
** Error (suppressible): ../../hdl/rtl/riscv/riscv_isa_c_pkg.sv(250): (vopt-8386) Illegal assignment to type 'enum reg[6:2] ' from type 'reg': An enum variable may only be assigned the same enum typed variable or one of its values.
```

Workaround:

Not great, might have other consequences.
Just skip the default `'{var:val}`.

## Vivado synthesis

