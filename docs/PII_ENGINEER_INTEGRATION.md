# PII Engineer (pii.engineer) — Offline Integration Guide

## Why this setup
Office laptop blocks HuggingFace but allows GitHub. This workspace hosts the
models as a GitHub release (`models-v1`) and provides `scripts/setup_offline.sh`
to fetch them without HuggingFace.

## What's in the release `models-v1`
- `multi-ner.tar.gz`  (~1.4 GB) — GLiNER2 multilingual NER (13+ langs, 9 PII types)
- `chinese-ner.tar.gz` (~360 MB) — Chinese NER for CJK coverage

Total ~2.1 GB on disk after extraction.

## Office laptop steps
1. Clone this repo:
   `git clone https://github.com/avilbopalia/AI-playground.git`
2. Run:
   `cd AI-playground && bash scripts/setup_offline.sh`
   - Downloads + extracts models into `./models/`
   - Clones `pii.engineer` source (GitHub accessible)
   - Builds the Rust binary if `cargo` is installed
3. Install Rust (if missing):
   `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
4. ONNX Runtime (required at runtime, `ort` uses load-dynamic):
   - macOS: `brew install onnxruntime` (provides libonnxruntime.dylib)
   - or download from https://github.com/microsoft/onnxruntime/releases and set
     `ORT_DYLIB_PATH=/path/to/libonnxruntime.dylib`
5. Run the server:
   ```
   cd pii.engineer
   GLINER_MODELS=../models/PII-Engineer-Multi-NER-v2.1 \
   CHINESE_NER_MODEL=../models/PII-Engineer-Chinese-NER-v1.0 \
   ./target/release/pii-engineer-server
   ```
   API: `POST http://localhost:8000/api/detect` with `{"text": "..."}`.

## Model files expected (already normalized by script)
- Multi: `models/PII-Engineer-Multi-NER-v2.1/onnx/{encoder_int8,span_rep,count_pred,count_embed,classifier}.onnx`
  + `gliner_config.json` (renamed from HF `config.json`)
- Chinese: `models/PII-Engineer-Chinese-NER-v1.0/{model.onnx,model.onnx.data,tokenizer.json,tokenizer_config.json,config.json}`

## Notes
- Models are gitignored (too large); always fetch from release `models-v1`.
- If you re-download models, keep `gliner_config.json` (the loader reads that name).
- License: pii.engineer is AGPL-3.0; commercial license at pii.engineer.
