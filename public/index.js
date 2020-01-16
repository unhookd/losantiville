/* */

window.addEventListener('DOMContentLoaded', (contentLoadedEvent) => {
  var dashboardContainer = document.getElementById("dashboard-container")

  var indicateProgress = function(element) {
    var progressIndicator = document.createElement("progress");

    while (element.firstChild) {
      element.removeChild(element.firstChild);
    }

    element.appendChild(progressIndicator);
  };

  var upload = function(formData) {
    fetch('/', {
      method: 'POST',
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      body: formData
    })
    .then(response => {
      return response.text()
    })
    .then(dashboardHtml => {
      morphdom(dashboardContainer, dashboardHtml, {
        childrenOnly: true,
        onBeforeElUpdated: function(fromEl, toEl) {
          if (fromEl.isEqualNode(toEl)) {
            return false
          }

          return true
        },
      });

      //console.log("TODO LOOP");
      //setTimeout(upload, 5000, form);
    })
    .catch(e => {
      console.log('There has been a problem with your fetch operation: ' + e.message);
      indicateProgress(dashboardContainer);
    });
  };

  var onSelectFile = function(ev) {
    ev.preventDefault();

    this.parentNode.parentNode.removeChild(this.parentNode); // lol

		var file = this.files[0];
		var formData = new FormData();
    formData.append("specification", file, "specification.yml");
    upload(formData);

    indicateProgress(dashboardContainer);

    return false;
  }

  var input = document.getElementById('specification');
  var form = document.getElementById('form');
  var submit = document.getElementById('submit');

  input.addEventListener('change', onSelectFile, false);
  form.addEventListener('submit', onSelectFile.bind(input), false);
  submit.focus();
});
