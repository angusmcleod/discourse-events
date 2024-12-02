const eventsClients = {
  discourse_events: {
    none: false,
    community: true,
    business: true,
  },
};

const features = {
  provider: {
    provider_type: {
      icalendar: {
        none: false,
        community: true,
        business: true,
      },
      google: {
        none: false,
        community: false,
        business: true,
      },
      outlook: {
        none: false,
        community: false,
        business: true,
      },
    },
  },
  source: {
    import_type: {
      import: {
        none: false,
        community: true,
        business: true,
      },
      import_publish: {
        none: false,
        community: false,
        business: true,
      },
      publish: {
        none: false,
        community: false,
        business: true,
      },
    },
    topic_sync: {
      manual: {
        none: false,
        community: true,
        business: true,
      },
      auto: {
        none: false,
        community: false,
        business: true,
      },
    },
    client: {
      discourse_events: {
        none: false,
        community: true,
        business: true,
      },
    },
  },
  connection: eventsClients,
};

export default {
  business: {
    subscribed: true,
    product: "business",
    features,
  },
  community: {
    subscribed: true,
    product: "community",
    features,
  },
};
