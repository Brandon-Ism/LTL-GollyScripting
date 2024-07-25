let savedColors = [];

function loadSavedColors() {
    const storedColors = localStorage.getItem('savedColors');
    if (storedColors) {
        savedColors = JSON.parse(storedColors);
        displaySavedColors();
    }
}

function updateColorFromSliders() {
    var red = document.getElementById('red').value;
    var green = document.getElementById('green').value;
    var blue = document.getElementById('blue').value;
    updateColorDisplay(red, green, blue);
}

function updateColorFromWheel() {
    const colorHex = document.getElementById('colorWheel').value;
    const rgb = hexToRgb(colorHex);
    updateColorDisplay(rgb.r, rgb.g, rgb.b);
}

function hexToRgb(hex) {
    var r = parseInt(hex.substr(1, 2), 16);
    var g = parseInt(hex.substr(3, 2), 16);
    var b = parseInt(hex.substr(5, 2), 16);
    return { r, g, b };
}

function updateColorDisplay(red, green, blue) {
    var colorDisplay = document.getElementById('colorDisplay');
    colorDisplay.style.backgroundColor = `rgb(${red}, ${green}, ${blue})`;

    document.getElementById('red').value = red;
    document.getElementById('green').value = green;
    document.getElementById('blue').value = blue;

    document.getElementById('redValue').textContent = red;
    document.getElementById('greenValue').textContent = green;
    document.getElementById('blueValue').textContent = blue;

    // Update the text to display RGB values separated by spaces
    document.getElementById('rgbValues').textContent = `${red} ${green} ${blue}`;
}


function saveColor() {
    const red = document.getElementById('red').value;
    const green = document.getElementById('green').value;
    const blue = document.getElementById('blue').value;

    const colorString = `rgb(${red} ${green} ${blue})`;
    savedColors.push(colorString);
    localStorage.setItem('savedColors', JSON.stringify(savedColors));
    displaySavedColors();
}

function displaySavedColors() {
const container = document.getElementById('savedColors');
container.innerHTML = '';
savedColors.forEach(function(color, index) {
const colorDiv = document.createElement('div');
colorDiv.style.backgroundColor = color;
colorDiv.textContent = color;
    const deleteButton = document.createElement('button');
    deleteButton.textContent = 'Remove';
    deleteButton.onclick = function() {
        removeColor(index);
    };

    colorDiv.appendChild(deleteButton);
    container.appendChild(colorDiv);
});
}

function removeColor(index) {
savedColors.splice(index, 1);
localStorage.setItem('savedColors', JSON.stringify(savedColors));
displaySavedColors();
}
document.getElementById('colorWheel').addEventListener('input', updateColorFromWheel);
document.getElementById('red').addEventListener('input', updateColorFromSliders);
document.getElementById('green').addEventListener('input', updateColorFromSliders);
document.getElementById('blue').addEventListener('input', updateColorFromSliders);
document.getElementById('saveColor').addEventListener('click', saveColor);


loadSavedColors();
updateColorFromSliders(); // Initialize with default slider values