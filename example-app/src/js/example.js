import { LiveActivity } from 'capacitor-live-activity';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    LiveActivity.echo({ value: inputValue })
}
