<script>
  import Modal from 'app/components/common/Modal'
  import Clan from 'models/Clan'

  export default Vue.extend({
    components: {
      Modal
    },
    props: {
      // If you want to edit an existing clan's name/description/type, pass it as a prop:
      clan: {
        type: Object,
        default: null
      }
    },
    data: () => ({
      name: '',
      description: '',
      isPublic: true
    }),
    methods: {
      async submit () {
        if (!this.isPublic && !me.isPremium()) {
          noty({ type: 'error', text: 'Must be a subscriber to create private clans', timeout: 3000 })
          return
        } else if (this.name.length < 2) {
          noty({ type: 'error', text: 'Must have at least 2 letters for the clan name', timeout: 3000 })
          return
        }

        if (this.clan) {
          await this.updateClan()
        } else {
          await this.createNewClan()
        }
      },
      async createNewClan () {
        try {
          // NOTE: Would prefer to move these to Vuex, keeping it simple for now:
          const clan = new Clan()
          clan.set('type', this.isPublic ? 'public' : 'private')
          clan.set('name', this.name)
          clan.set('description', this.description)
          // Assume this will fail if the clan name exists
          const savedClan = await clan.save({})

          application.router.navigate(`/league/${savedClan._id}`, { trigger: true })
          this.$emit('close')
        } catch (e) {
          if (e.errorName === 'Conflict' || e.code === 409) {
            noty({ type: 'error', text: 'Clan name already exists', timeout: 3000 })
            return
          } else {
            throw e
          }
        }
      },

      async updateClan () {
        try {
          const clan = new Clan({ _id: this.clan._id })
          clan.set('type', this.isPublic ? 'public' : 'private')
          clan.set('name', this.name)
          clan.set('description', this.description)

          // NOTE: May not not need to set these. Would prefer to move these to Vuex:
          clan.set('ownerID', this.clan.ownerID)
          clan.set('dashboardType', this.clan.dashboardType)
          await clan.save({})
          this.$emit('close')
        } catch (e) {
          if (e.errorName === 'Conflict' || e.code === 409) {
            noty({ type: 'error', text: 'Clan name already exists', timeout: 3000 })
            return
          } else {
            throw e
          }
        }
      }

    }
  })
</script>

<template>
  <modal @close="$emit('close')" title="Create clan" id="clan-creation-modal">
    <div class="container">
      <div>
        <label for="input-name">Clan name:</label>
        <input id="input-name" type="text" v-model="name" />
      </div>

      <div>
        <label for="input-description">Description:</label>
        <textarea id="input-description" type="text" rows=2 v-model="description" />
      </div>

      <div>
        <label for="input-is-public">Public:</label>
        <input id="input-is-public" type="checkbox" v-model="isPublic" />
      </div>

      <button @click.prevent="submit">Create clan</button>
    </div>
  </modal>
</template>

<style scoped>
#clan-creation-modal label {
  color: black;
  min-width: 20%;
  padding-right: 20px;
  margin-bottom: 10px;
}

#clan-creation-modal .container > div {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

</style>