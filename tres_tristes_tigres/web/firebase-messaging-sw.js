importScripts('https://www.gstatic.com/firebasejs/9.21.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.21.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDf8hXTJqpiNtaq45kGMxMkwUmRnlTdTCM",
  authDomain: "pushnotification-86d31.firebaseapp.com",
  projectId: "pushnotification-86d31",
  storageBucket: "pushnotification-86d31.firebasestorage.app",
  messagingSenderId: "283700309050",
  appId: "1:283700309050:web:de2d13c5f77ce5def2d903",
});

const messaging = firebase.messaging();
