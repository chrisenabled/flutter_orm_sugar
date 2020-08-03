<template>
  <div class="q-pa-md">
    <q-table
      grid
      card-class="bg-primary text-white"
      title="Objects"
      :data="Object.values(config.models)"
      :columns="columns"
      row-key="name"
      :filter="filter"
      no-data-label="I didn't find anything for you"
      no-results-label="The filter didn't uncover any results"
    >
      <template v-slot:top-right>
        <q-input class="bg-grey-4 q-py-xs q-px-xl" 
            borderless dense debounce="300" v-model="filter" 
            placeholder="Search">
          <template v-slot:append>
            <q-icon name="ti-search" />
          </template>
        </q-input>
      </template>

      <template v-slot:no-data="{ icon, message, filter }">
        <div class="full-width column flex-center q-gutter-sm bg-pink-2 q-py-sm">
          <q-icon size="2em" :name="filter? icon:icon"></q-icon>
          <span>
            <q-icon name="ti-face-sad"></q-icon>
            Well this is sad... {{ message }}
          </span>
        </div>
      </template>
    </q-table>
  </div>
</template>



<script>
module.exports = {
  data () {
    return {
      filter: '',
      columns: [
        {
          name: 'name',
          required: true,
          label: 'Object',
          align: 'left',
          field: 'modelName',
          format: val => `${val}`,
          sortable: true,
          headerClasses: 'bg-pink'
        },
        {
          name: 'fieldsCount',
          align: 'left',
          label: 'No. of Fields',
          field: row => row.modelFields.length,
          sortable: true
        },
        { 
            name: 'database', 
            label: 'Database', 
            align: 'left',
            field: 'repository', 
            sortable: true 
        },
        { 
            name: 'repoName', 
            label: 'Repo/Table', 
            align: 'left',
            field: 'repoName', 
            sortable: true 
        },
        {
          name: 'relationshipsCount',
          label: 'No. of Relations',
          align: 'left',
          field: row => Object.keys(row.relationships).length,
          sortable: true
        }
      ],
    }
  },
  mounted: function () {
    this.$nav.current = 'Objects'
  },
  computed: {
    config() {
      return this.$store.config.data
    },
  }
}
</script>
