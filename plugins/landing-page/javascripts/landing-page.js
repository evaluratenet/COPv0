// Landing Page JavaScript for Circle of Peers

document.addEventListener('DOMContentLoaded', function() {
  // Smooth scrolling for anchor links
  const anchorLinks = document.querySelectorAll('a[href^="#"]');
  
  anchorLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      
      const targetId = this.getAttribute('href');
      const targetElement = document.querySelector(targetId);
      
      if (targetElement) {
        const headerHeight = document.querySelector('.landing-header').offsetHeight;
        const targetPosition = targetElement.offsetTop - headerHeight - 20;
        
        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
      }
    });
  });

  // Header scroll effect
  const header = document.querySelector('.landing-header');
  let lastScrollTop = 0;
  
  window.addEventListener('scroll', function() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    
    if (scrollTop > 100) {
      header.style.backgroundColor = 'rgba(255, 255, 255, 0.98)';
      header.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
    } else {
      header.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
      header.style.boxShadow = 'none';
    }
    
    lastScrollTop = scrollTop;
  });

  // Intersection Observer for animations
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
      }
    });
  }, observerOptions);

  // Observe elements for animation
  const animatedElements = document.querySelectorAll('.feature-card, .step, .value-card, .snapshot-card');
  animatedElements.forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
  });

  // Button hover effects
  const buttons = document.querySelectorAll('.btn');
  buttons.forEach(button => {
    button.addEventListener('mouseenter', function() {
      this.style.transform = 'translateY(-2px)';
    });
    
    button.addEventListener('mouseleave', function() {
      this.style.transform = 'translateY(0)';
    });
  });

  // Mobile menu toggle (if needed)
  const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
  const mainNav = document.querySelector('.main-nav');
  
  if (mobileMenuToggle && mainNav) {
    mobileMenuToggle.addEventListener('click', function() {
      mainNav.classList.toggle('active');
      this.classList.toggle('active');
    });
  }

  // Form validation for contact forms (if any)
  const contactForms = document.querySelectorAll('form[data-validate]');
  contactForms.forEach(form => {
    form.addEventListener('submit', function(e) {
      const requiredFields = form.querySelectorAll('[required]');
      let isValid = true;
      
      requiredFields.forEach(field => {
        if (!field.value.trim()) {
          isValid = false;
          field.classList.add('error');
        } else {
          field.classList.remove('error');
        }
      });
      
      if (!isValid) {
        e.preventDefault();
        showNotification('Please fill in all required fields.', 'error');
      }
    });
  });

  // Community Statistics Update Functionality
  function updateStatisticsDisplay() {
    const statElements = document.querySelectorAll('.stat-value');
    
    statElements.forEach(element => {
      const originalValue = element.textContent;
      element.style.transition = 'all 0.3s ease';
      element.style.transform = 'scale(1.1)';
      element.style.color = '#3498db';
      
      setTimeout(() => {
        element.style.transform = 'scale(1)';
        element.style.color = '';
      }, 300);
    });
  }

  // Auto-refresh statistics every 5 minutes (if user is on the page)
  let statisticsRefreshInterval;
  
  function startStatisticsRefresh() {
    statisticsRefreshInterval = setInterval(() => {
      // Only refresh if the page is visible
      if (!document.hidden) {
        fetch('/landing/refresh-statistics', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
            'Content-Type': 'application/json'
          }
        })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            // Reload the page to show updated statistics
            window.location.reload();
          }
        })
        .catch(error => {
          console.log('Statistics refresh failed:', error);
        });
      }
    }, 5 * 60 * 1000); // 5 minutes
  }

  // Start auto-refresh if user is admin
  if (document.body.classList.contains('admin-user')) {
    startStatisticsRefresh();
  }

  // Manual refresh button for admins
  const refreshStatsButton = document.querySelector('.refresh-statistics');
  if (refreshStatsButton) {
    refreshStatsButton.addEventListener('click', function(e) {
      e.preventDefault();
      
      this.disabled = true;
      this.textContent = 'Updating...';
      
      fetch('/landing/refresh-statistics', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Content-Type': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          showNotification('Statistics updated successfully!', 'success');
          window.location.reload();
        } else {
          showNotification('Failed to update statistics.', 'error');
        }
      })
      .catch(error => {
        showNotification('Error updating statistics.', 'error');
        console.error('Statistics refresh error:', error);
      })
      .finally(() => {
        this.disabled = false;
        this.textContent = 'Refresh Statistics';
      });
    });
  }

  // Notification system
  function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    // Add styles
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      padding: 15px 20px;
      border-radius: 6px;
      color: white;
      font-weight: 500;
      z-index: 10000;
      transform: translateX(100%);
      transition: transform 0.3s ease;
      max-width: 300px;
    `;
    
    if (type === 'error') {
      notification.style.backgroundColor = '#e74c3c';
    } else if (type === 'success') {
      notification.style.backgroundColor = '#27ae60';
    } else {
      notification.style.backgroundColor = '#3498db';
    }
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after 5 seconds
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)';
      setTimeout(() => {
        document.body.removeChild(notification);
      }, 300);
    }, 5000);
  }

  // Lazy loading for images
  const images = document.querySelectorAll('img[data-src]');
  const imageObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target;
        img.src = img.dataset.src;
        img.classList.remove('lazy');
        imageObserver.unobserve(img);
      }
    });
  });

  images.forEach(img => imageObserver.observe(img));

  // Analytics tracking (if needed)
  function trackEvent(eventName, properties = {}) {
    if (typeof gtag !== 'undefined') {
      gtag('event', eventName, properties);
    }
    
    if (typeof fbq !== 'undefined') {
      fbq('track', eventName, properties);
    }
  }

  // Track button clicks
  const trackableButtons = document.querySelectorAll('[data-track]');
  trackableButtons.forEach(button => {
    button.addEventListener('click', function() {
      const eventName = this.dataset.track;
      trackEvent(eventName, {
        button_text: this.textContent,
        page: window.location.pathname
      });
    });
  });

  // Performance monitoring
  window.addEventListener('load', function() {
    if ('performance' in window) {
      const perfData = performance.getEntriesByType('navigation')[0];
      const loadTime = perfData.loadEventEnd - perfData.loadEventStart;
      
      console.log(`Page load time: ${loadTime}ms`);
      
      if (loadTime > 3000) {
        console.warn('Page load time is slow. Consider optimizing.');
      }
    }
  });

  // Accessibility improvements
  const focusableElements = document.querySelectorAll('a, button, input, textarea, select, [tabindex]:not([tabindex="-1"])');
  
  focusableElements.forEach(element => {
    element.addEventListener('focus', function() {
      this.style.outline = '2px solid #3498db';
      this.style.outlineOffset = '2px';
    });
    
    element.addEventListener('blur', function() {
      this.style.outline = '';
      this.style.outlineOffset = '';
    });
  });

  // Keyboard navigation
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      // Close any open modals or menus
      const activeModals = document.querySelectorAll('.modal.active, .menu.active');
      activeModals.forEach(modal => {
        modal.classList.remove('active');
      });
    }
  });

  // Print styles
  window.addEventListener('beforeprint', function() {
    document.body.classList.add('printing');
  });
  
  window.addEventListener('afterprint', function() {
    document.body.classList.remove('printing');
  });

  // Page visibility API for statistics refresh
  document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
      // Clear interval when page is hidden
      if (statisticsRefreshInterval) {
        clearInterval(statisticsRefreshInterval);
      }
    } else {
      // Restart interval when page becomes visible
      if (document.body.classList.contains('admin-user')) {
        startStatisticsRefresh();
      }
    }
  });
});

// Utility functions
const LandingPageUtils = {
  // Debounce function
  debounce: function(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  },

  // Throttle function
  throttle: function(func, limit) {
    let inThrottle;
    return function() {
      const args = arguments;
      const context = this;
      if (!inThrottle) {
        func.apply(context, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  },

  // Get element position
  getElementPosition: function(element) {
    const rect = element.getBoundingClientRect();
    return {
      top: rect.top + window.pageYOffset,
      left: rect.left + window.pageXOffset,
      width: rect.width,
      height: rect.height
    };
  },

  // Check if element is in viewport
  isInViewport: function(element) {
    const rect = element.getBoundingClientRect();
    return (
      rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
      rect.right <= (window.innerWidth || document.documentElement.clientWidth)
    );
  }
};

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
  module.exports = LandingPageUtils;
} 