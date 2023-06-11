prometheus "Brickyard" {
  uri         = "https://prometheus.brickyard.whitestar.systems"
  headers     = {
    "CF-Access-Client-Id": "${ENV_PINT_BRICKYARD_CLIENT_ID}",
    "CF-Access-Client-Secret": "${ENV_PINT_BRICKYARD_CLIENT_SECRET}"
  }
}