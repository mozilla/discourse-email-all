import { ajax } from 'discourse/lib/ajax'

export default Ember.Controller.extend({
  actions: {
    send () {
      ajax('/admin/plugins/email-all', {
        type: 'POST',
        data: {
          subject: this.get('subject'),
          body: this.get('body')
        }
      }).then(() => {
        alert('Success! Jobs enqueued, emails being sent')
      }).catch(() => {
        alert('Error')
      })
    }
  }
})
