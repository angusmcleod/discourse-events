const eventsClients = {
  discourse_events: {
    none: false,
    community: true,
    business: true,
  },
};

const features = {
  provider: {
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
  source: {
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
