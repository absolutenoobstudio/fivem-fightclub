(function () {
  const app = document.getElementById('app');
  const statusEl = document.getElementById('status');
  const closeBtn = document.getElementById('close');

  const resourceName =
    typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'fivem-fightclub';

  function setVisible(visible) {
    if (!app) return;
    app.classList.toggle('hidden', !visible);
    app.setAttribute('aria-hidden', visible ? 'false' : 'true');
  }

  function setStatus(text) {
    if (statusEl) statusEl.textContent = text;
  }

  window.addEventListener('message', function (event) {
    const data = event.data;
    if (!data || typeof data !== 'object') return;

    if (data.action === 'open') {
      setVisible(true);
      if (data.status) setStatus(String(data.status));
    } else if (data.action === 'close') {
      setVisible(false);
    } else if (data.action === 'status' && data.text != null) {
      setStatus(String(data.text));
    }
  });

  if (closeBtn) {
    closeBtn.addEventListener('click', function () {
      setVisible(false);
      fetch('https://' + resourceName + '/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({}),
      }).catch(function () {});
    });
  }
})();
