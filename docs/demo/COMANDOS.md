# Comandos de la demo

```bash
# 30 minutos antes
./tools/demo-commands.sh preflight
./tools/demo-commands.sh agentic-eval --replay

# recorrido
./tools/demo-commands.sh module-0 --step
./tools/demo-commands.sh module-3 --step
./tools/demo-commands.sh negative-control --step
./tools/demo-commands.sh agentic-eval
./tools/demo-commands.sh conformance
./tools/demo-commands.sh proof

# a mano, si hacen falta
./tools/demo-commands.sh viewer nightly-batch
./tools/demo-commands.sh deps nightly-batch
./tools/demo-commands.sh explore nightly-batch
./tools/demo-commands.sh agentic-eval --replay
```
