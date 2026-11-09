// Local-only OCR. The application serves the engine and French language model.
// A separate worker per scan is always terminated, including on timeout/error.
window._extractText = async function (image, options) {
  const base = new URL('ocr/', document.baseURI).href;
  let worker;
  let timer;
  let expired = false;
  const work = async () => {
    if (!window.Tesseract) {
      await new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = base + 'tesseract.min.js';
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      });
    }
    if (expired) throw new Error('OCR timeout');
    worker = await Tesseract.createWorker('fra', 1, {
      workerPath: base + 'worker.min.js', corePath: base,
      langPath: new URL('assets/assets/tessdata/', document.baseURI).href,
      gzip: false,
    });
    if (expired) { await worker.terminate(); throw new Error('OCR timeout'); }
    await worker.setParameters(options.args || {});
    const result = await worker.recognize(image);
    return result.data.text;
  };
  try {
    return await Promise.race([work(), new Promise((_, reject) => {
      timer = setTimeout(() => { expired = true; reject(new Error('OCR timeout')); }, 60000);
    })]);
  } finally {
    clearTimeout(timer);
    if (worker) await worker.terminate();
  }
};
