import {LiveActivity} from "capacitor-live-activity";
import {Camera, CameraResultType, CameraSource} from "@capacitor/camera";

window.onerror = (msg, src, lineno, colno, err) => {
    console.error("Global JS Error", { msg, src, lineno, colno, err });
  };

let base64Image = null;

window.selectImage = async () => {
  try {
    const image = await Camera.getPhoto({
        quality: 90,
        allowEditing: false,
        resultType: CameraResultType.Base64,
        source: CameraSource.Prompt
      });

    base64Image = image.base64String;
    console.log("Base64 length", base64Image?.length);

    const preview = document.getElementById("previewImage");
    preview.src = `data:image/jpeg;base64,${base64Image}`;
    preview.style.display = "block";
    preview.alt = "Selected image preview";
    preview.setAttribute("aria-label", "Selected image");
  } catch (error) {
    console.error("Image selection failed", error);
  }
};

window.clearImage = () => {
  base64Image = null;
  const preview = document.getElementById("previewImage");
  preview.src = "";
  preview.style.display = "none";
};

window.startActivity = async () => {
  console.log("Start button clicked");

  const inputTitleValue = document.getElementById("titleInput").value;
  const inputSubtitleValue = document.getElementById("subtitleInput").value;
  const durationValue = parseInt(document.getElementById("durationSelect").value, 10);
  const timerEndDate = new Date(Date.now() + durationValue).toISOString();

  const startActivity = {
    id: "demo-activity",
    title: inputTitleValue,
    subtitle: inputSubtitleValue,
    timerEndDate,
    imageBase64: base64Image
  };
  console.log("StartActivity Params", startActivity);

  try {
    await LiveActivity.startActivity(startActivity);
  } catch (error) {
    console.error("startActivity failed", error);
  }
};

window.updateActivity = async () => {
  const inputTitleValue = document.getElementById("titleInput").value;
  const inputSubtitleValue = document.getElementById("subtitleInput").value;

  try {
    await LiveActivity.updateActivity({id: "demo-activity", title: inputTitleValue, subtitle: inputSubtitleValue, imageBase64: base64Image});
  } catch (error) {
    console.error("updateActivity failed", error);
  }
};

window.endActivity = async () => {
  try {
    await LiveActivity.endActivity({id: "demo-activity", dismissed: true});
  } catch (error) {
    console.error("endActivity failed", error);
  }
};
