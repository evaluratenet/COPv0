// Session Management JavaScript
// Handles client-side session management and inactivity warnings

(function() {
  'use strict';
  
  let inactivityTimer;
  let warningTimer;
  let sessionCheckInterval;
  let isWarningShown = false;
  
  // Initialize session management
  function initSessionManagement() {
    if (!Discourse.User.current()) return;
    
    // Start session monitoring
    startSessionMonitoring();
    
    // Set up activity listeners
    setupActivityListeners();
    
    // Check session status every 30 seconds
    sessionCheckInterval = setInterval(checkSessionStatus, 30000);
  }
  
  // Start session monitoring
  function startSessionMonitoring() {
    // Check initial session status
    checkSessionStatus();
  }
  
  // Check session status from server
  function checkSessionStatus() {
    $.ajax({
      url: '/session/status',
      type: 'GET',
      dataType: 'json'
    }).then(function(response) {
      handleSessionResponse(response);
    }).catch(function(error) {
      console.error('Session status check failed:', error);
    });
  }
  
  // Handle session response from server
  function handleSessionResponse(response) {
    switch(response.status) {
      case 'active':
        resetInactivityTimers();
        hideInactivityWarning();
        break;
        
      case 'inactivity_warning':
        showInactivityWarning(response);
        break;
        
      case 'inactive':
        handleSessionTimeout();
        break;
        
      case 'not_logged_in':
        redirectToLogin();
        break;
    }
  }
  
  // Show inactivity warning
  function showInactivityWarning(response) {
    if (isWarningShown) return;
    
    isWarningShown = true;
    
    const warningHtml = `
      <div id="inactivity-warning" class="inactivity-warning-overlay">
        <div class="inactivity-warning-modal">
          <div class="warning-header">
            <i class="fa fa-exclamation-triangle"></i>
            <h3>Session Inactivity Warning</h3>
          </div>
          <div class="warning-body">
            <p>You have been inactive for 10 minutes. Your session will be automatically logged out in 5 minutes if you don't respond.</p>
            <p><strong>Last Activity:</strong> ${formatTime(response.last_activity)}</p>
          </div>
          <div class="warning-actions">
            <button class="btn btn-primary" id="continue-session">Continue Session</button>
            <button class="btn btn-danger" id="end-session">End Session</button>
          </div>
        </div>
      </div>
    `;
    
    $('body').append(warningHtml);
    
    // Set up warning timers
    warningTimer = setTimeout(() => {
      hideInactivityWarning();
      checkSessionStatus(); // Check if user responded
    }, 300000); // 5 minutes
    
    // Set up button handlers
    $('#continue-session').on('click', continueSession);
    $('#end-session').on('click', endSession);
  }
  
  // Hide inactivity warning
  function hideInactivityWarning() {
    $('#inactivity-warning').remove();
    isWarningShown = false;
    
    if (warningTimer) {
      clearTimeout(warningTimer);
      warningTimer = null;
    }
  }
  
  // Continue session
  function continueSession() {
    $.ajax({
      url: '/session/inactivity_response',
      type: 'POST',
      dataType: 'json',
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    }).then(function(response) {
      if (response.success) {
        hideInactivityWarning();
        resetInactivityTimers();
        showSuccessMessage('Session continued successfully.');
      }
    }).catch(function(error) {
      console.error('Failed to continue session:', error);
      showErrorMessage('Failed to continue session. Please try again.');
    });
  }
  
  // End session
  function endSession() {
    if (confirm('Are you sure you want to end your session? You will be logged out immediately.')) {
      window.location.href = '/logout';
    }
  }
  
  // Handle session timeout
  function handleSessionTimeout() {
    showErrorMessage('Your session has timed out due to inactivity. You have been logged out.');
    setTimeout(() => {
      window.location.href = '/login';
    }, 3000);
  }
  
  // Redirect to login
  function redirectToLogin() {
    window.location.href = '/login';
  }
  
  // Reset inactivity timers
  function resetInactivityTimers() {
    if (inactivityTimer) {
      clearTimeout(inactivityTimer);
    }
    
    // Set new inactivity timer (10 minutes)
    inactivityTimer = setTimeout(() => {
      checkSessionStatus();
    }, 600000); // 10 minutes
  }
  
  // Set up activity listeners
  function setupActivityListeners() {
    const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'];
    
    events.forEach(event => {
      $(document).on(event, resetInactivityTimers);
    });
  }
  
  // Format time for display
  function formatTime(timestamp) {
    if (!timestamp) return 'Unknown';
    
    const date = new Date(timestamp);
    return date.toLocaleString();
  }
  
  // Show success message
  function showSuccessMessage(message) {
    const $message = $(`<div class="alert alert-success">${message}</div>`);
    $('.d-header').after($message);
    
    setTimeout(() => {
      $message.fadeOut(() => $message.remove());
    }, 5000);
  }
  
  // Show error message
  function showErrorMessage(message) {
    const $message = $(`<div class="alert alert-danger">${message}</div>`);
    $('.d-header').after($message);
    
    setTimeout(() => {
      $message.fadeOut(() => $message.remove());
    }, 5000);
  }
  
  // Cleanup on page unload
  function cleanup() {
    if (sessionCheckInterval) {
      clearInterval(sessionCheckInterval);
    }
    if (inactivityTimer) {
      clearTimeout(inactivityTimer);
    }
    if (warningTimer) {
      clearTimeout(warningTimer);
    }
  }
  
  // Initialize when DOM is ready
  $(document).ready(function() {
    initSessionManagement();
    
    // Cleanup on page unload
    $(window).on('beforeunload', cleanup);
  });
  
  // Export for testing
  window.SessionManagement = {
    initSessionManagement,
    checkSessionStatus,
    showInactivityWarning,
    hideInactivityWarning,
    continueSession,
    endSession,
    cleanup
  };
  
})(); 