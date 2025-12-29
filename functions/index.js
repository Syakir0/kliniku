const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendOtpEmail = functions.firestore
  .document("email_verification/{uid}")
  .onCreate(async (snap, context) => {
    const uid = context.params.uid;
    const data = snap.data();

    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (!userDoc.exists) return null;

    const email = userDoc.data().email;
    const otp = data.kode;

    const msg = {
      to: email,
      from: functions.config().sendgrid.sender,
      subject: "Kode Verifikasi Akun Kliniku",
      html: `
        <h2>Verifikasi Email</h2>
        <p>Kode OTP kamu:</p>
        <h1>${otp}</h1>
        <p>Berlaku 5 menit</p>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log("OTP terkirim ke:", email);
    } catch (error) {
      console.error("Gagal kirim email:", error);
    }

    return null;
  });
