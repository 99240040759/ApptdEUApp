importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAX5CS6I6of67DS2zC51obpO7-MvR2gxz0",
  authDomain: "samezz-3f3a9.firebaseapp.com",
  projectId: "samezz-3f3a9",
  storageBucket: "samezz-3f3a9.firebasestorage.app",
  messagingSenderId: "708285207203",
  appId: "1:708285207203:web:c260a4156d60fdd5412516",
  measurementId: "G-930YEQF7N2"
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((message) => {
  console.log("Background message:", message);
});
