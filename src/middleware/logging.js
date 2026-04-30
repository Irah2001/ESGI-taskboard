const loggingMiddleware = (req, res, next) => {
  const start = Date.now();

  // eslint-disable-next-line no-console
  console.log(`--> ${req.method} ${req.url}`);

  res.on('finish', () => {
    const duration = Date.now() - start;
    // eslint-disable-next-line no-console
    console.log(`<-- ${req.method} ${req.url} ${res.statusCode} ${duration}ms`);
  });

  next();
};

module.exports = { loggingMiddleware };
