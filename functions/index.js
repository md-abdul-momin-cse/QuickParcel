const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

if (!admin.apps.length) {
  admin.initializeApp();
}

const SSL_STORE_ID = "abdul67f7d33d97f1e";
const SSL_STORE_PASS = "abdul67f7d33d97f1e@ssl";
const SSL_API_BASE = "https://sandbox.sslcommerz.com";
const CALLBACK_URL =
  "https://us-central1-quickparcel-f0b4e.cloudfunctions.net/sslCommerzCallback";

function sendJson(res, code, payload) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.status(code).json(payload);
}

exports.createSslCommerzSession = onRequest(async (req, res) => {
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed" });
  }

  try {
    const {
      orderId,
      amount,
      customerName,
      customerPhone,
      customerEmail,
      paymentProvider,
    } = req.body || {};

    if (!orderId || !amount) {
      return sendJson(res, 400, { error: "orderId and amount are required" });
    }

    const payload = new URLSearchParams({
      store_id: SSL_STORE_ID,
      store_passwd: SSL_STORE_PASS,
      total_amount: String(amount),
      currency: "BDT",
      tran_id: orderId,
      success_url: `${CALLBACK_URL}?status=success`,
      fail_url: `${CALLBACK_URL}?status=failed`,
      cancel_url: `${CALLBACK_URL}?status=cancelled`,
      ipn_url: `${CALLBACK_URL}?status=ipn`,
      shipping_method: "NO",
      product_name: "Quick Parcel Delivery",
      product_category: "Courier",
      product_profile: "general",
      cus_name: customerName || "Quick Parcel User",
      cus_email: customerEmail || "customer@quickparcel.com",
      cus_add1: "Dhaka",
      cus_city: "Dhaka",
      cus_country: "Bangladesh",
      cus_phone: customerPhone || "01700000000",
      ship_name: customerName || "Quick Parcel User",
      ship_add1: "Dhaka",
      ship_city: "Dhaka",
      ship_country: "Bangladesh",
      multi_card_name: "bkash,rocket,visacard",
      cart: "QuickParcelSandboxCart",
      product_amount: String(amount),
      vat: "0",
      discount_amount: "0",
      convenience_fee: "0",
      value_a: paymentProvider || "Online",
      value_b: "quick_parcel",
      value_c: "mobile_app_sandbox",
      value_d: "sandbox",
    });

    const response = await fetch(`${SSL_API_BASE}/gwprocess/v4/api.php`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: payload,
    });

    const result = await response.json();

    if (result.status !== "SUCCESS" || !result.GatewayPageURL) {
      logger.error("SSL session create failed", { result });
      return sendJson(res, 400, {
        error: "Failed to create SSLCommerz session",
        details: result,
      });
    }

    return sendJson(res, 200, {
      gatewayUrl: result.GatewayPageURL,
      sessionkey: result.sessionkey,
      tranId: orderId,
      callbackUrl: CALLBACK_URL,
      mode: "sandbox",
    });
  } catch (error) {
    logger.error("createSslCommerzSession error", {
      error: error instanceof Error ? error.message : String(error),
    });
    return sendJson(res, 500, { error: "Internal server error" });
  }
});

exports.validateSslCommerzPayment = onRequest(async (req, res) => {
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed" });
  }

  try {
    const { tranId } = req.body || {};
    if (!tranId) {
      return sendJson(res, 400, { error: "tranId is required" });
    }

    const params = new URLSearchParams({
      val_id: "",
      store_id: SSL_STORE_ID,
      store_passwd: SSL_STORE_PASS,
      format: "json",
      tran_id: tranId,
    });

    const response = await fetch(
      `${SSL_API_BASE}/validator/api/validationserverAPI.php?${params.toString()}`,
    );
    const result = await response.json();

    const validStatuses = new Set(["VALID", "VALIDATED"]);
    const isValid = validStatuses.has(String(result.status || "").toUpperCase());

    return sendJson(res, 200, {
      isValid,
      transactionStatus: result.status || "UNKNOWN",
      tranId,
      details: result,
    });
  } catch (error) {
    logger.error("validateSslCommerzPayment error", {
      error: error instanceof Error ? error.message : String(error),
    });
    return sendJson(res, 500, { error: "Internal server error" });
  }
});

exports.sslCommerzCallback = onRequest(async (req, res) => {
  const status = req.query.status || "unknown";

  res.set("Content-Type", "text/html; charset=utf-8");
  res.status(200).send(`
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <title>Payment Status</title>
        <style>
          body { font-family: Arial, sans-serif; background: #f1f7fb; margin: 0; }
          .box { max-width: 520px; margin: 60px auto; background: #fff; border-radius: 14px; padding: 24px; box-shadow: 0 8px 20px rgba(0,0,0,0.08); }
          h2 { margin-top: 0; color: #0D7D8F; }
          p { color: #334155; line-height: 1.5; }
        </style>
      </head>
      <body>
        <div class="box">
          <h2>Payment ${String(status).toUpperCase()}</h2>
          <p>You can now return to the Quick Parcel app.</p>
          <p>This window can be closed safely.</p>
        </div>
      </body>
    </html>
  `);
});

function getTransporter() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const secure = String(process.env.SMTP_SECURE || "false") === "true";
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    throw new Error("Missing SMTP credentials. Set SMTP_HOST, SMTP_USER, SMTP_PASS.");
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });
}

exports.sendVerificationOtp = onDocumentUpdated("users/{userId}", async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};

  const previousOtp = before.VerificationOtp;
  const otp = after.VerificationOtp;
  const toEmail = after.OtpEmail;
  const expiresAt = after.OtpTimestamp;

  // Send only when a new OTP is set/changed.
  if (!otp || otp === previousOtp) {
    return;
  }

  if (!toEmail) {
    logger.warn("OTP exists but OtpEmail is missing", { userId: event.params.userId });
    return;
  }

  const appName = "Quick Parcel";
  const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;

  const subject = `${appName} - Your verification code`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto;">
      <h2 style="color:#0D7D8F;">Verify your email</h2>
      <p>Your OTP code is:</p>
      <div style="font-size: 28px; font-weight: 700; letter-spacing: 6px; margin: 14px 0; color:#1A1A2E;">${otp}</div>
      <p>This code will expire at <b>${expiresAt || "soon"}</b>.</p>
      <p>If you did not request this, you can ignore this email.</p>
      <hr style="border:none;border-top:1px solid #eee;margin:20px 0;" />
      <p style="font-size:12px;color:#6b7280;">${appName}</p>
    </div>
  `;

  const text = [
    "Verify your email",
    `OTP: ${otp}`,
    expiresAt ? `Expires at: ${expiresAt}` : "",
    "If you did not request this, ignore this email.",
  ]
    .filter(Boolean)
    .join("\n");

  try {
    const transporter = getTransporter();
    await transporter.sendMail({
      from: fromAddress,
      to: toEmail,
      subject,
      text,
      html,
    });

    logger.info("OTP email sent", {
      userId: event.params.userId,
      toEmail,
    });
  } catch (error) {
    logger.error("Failed to send OTP email", {
      userId: event.params.userId,
      error: error instanceof Error ? error.message : String(error),
    });
    throw error;
  }
});
