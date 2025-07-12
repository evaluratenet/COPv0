import { withPluginApi } from "discourse/lib/plugin-api";
import { getOwner } from "discourse-common/lib/get-owner";

export default {
  name: "ai-moderation-flagging",
  
  initialize() {
    withPluginApi("0.8.31", api => {
      // Add flag button to posts
      api.decoratePost(this.addFlagButton.bind(this));
      
      // Add flag modal
      api.modifyClass("component:post-menu", {
        router: service(),
        
        flagPost(post) {
          this.showFlagModal(post);
        },
        
        showFlagModal(post) {
          const modal = getOwner(this).lookup("service:modal");
          modal.show("ai-moderation-flag", {
            model: {
              post: post,
              violationTypes: this.getViolationTypes()
            }
          });
        },
        
        getViolationTypes() {
          return [
            { id: 1, name: 'solicitation', description: 'Promotion or sales content', severity: 3 },
            { id: 2, name: 'pii', description: 'Personal identifiable information', severity: 4 },
            { id: 3, name: 'harassment', description: 'Hostile or inappropriate tone', severity: 5 },
            { id: 4, name: 'confidential', description: 'Company confidential information', severity: 4 },
            { id: 5, name: 'off_topic', description: 'Content unrelated to discussion', severity: 2 },
            { id: 6, name: 'spam', description: 'Repeated or automated content', severity: 3 },
            { id: 7, name: 'identity_leak', description: 'Revealing personal identity', severity: 4 },
            { id: 8, name: 'inappropriate', description: 'Inappropriate content for professional forum', severity: 3 }
          ];
        }
      });
    });
  },
  
  addFlagButton($elem, helper) {
    const post = helper.getModel();
    
    // Don't show flag button on own posts
    if (post.user_id === this.currentUser?.id) {
      return;
    }
    
    // Add flag button to post menu
    const $postMenu = $elem.find('.post-menu-area');
    if ($postMenu.length) {
      const $flagButton = $(`
        <li class="post-menu-area-flag">
          <a href="#" class="flag-post" title="Flag for violation">
            <i class="fa fa-flag"></i>
            <span>Flag</span>
          </a>
        </li>
      `);
      
      $flagButton.on('click', (e) => {
        e.preventDefault();
        this.showFlagModal(post);
      });
      
      $postMenu.append($flagButton);
    }
  },
  
  showFlagModal(post) {
    const modal = getOwner(this).lookup("service:modal");
    modal.show("ai-moderation-flag", {
      model: {
        post: post,
        violationTypes: this.getViolationTypes()
      }
    });
  },
  
  getViolationTypes() {
    return [
      { id: 1, name: 'solicitation', description: 'Promotion or sales content', severity: 3 },
      { id: 2, name: 'pii', description: 'Personal identifiable information', severity: 4 },
      { id: 3, name: 'harassment', description: 'Hostile or inappropriate tone', severity: 5 },
      { id: 4, name: 'confidential', description: 'Company confidential information', severity: 4 },
      { id: 5, name: 'off_topic', description: 'Content unrelated to discussion', severity: 2 },
      { id: 6, name: 'spam', description: 'Repeated or automated content', severity: 3 },
      { id: 7, name: 'identity_leak', description: 'Revealing personal identity', severity: 4 },
      { id: 8, name: 'inappropriate', description: 'Inappropriate content for professional forum', severity: 3 }
    ];
  }
}; 