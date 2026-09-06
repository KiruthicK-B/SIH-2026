const express = require('express');
const { isValidEntity } = require('./entities');
const store = require('./store');

const router = express.Router();

router.use('/:entity', (req, res, next) => {
  if (!isValidEntity(req.params.entity)) {
    return res.status(404).json({ error: `Unknown entity "${req.params.entity}"` });
  }
  next();
});

router.get('/:entity', async (req, res, next) => {
  try {
    res.json(await store.getAll(req.params.entity));
  } catch (err) {
    next(err);
  }
});

router.get('/:entity/:id', async (req, res, next) => {
  try {
    const item = await store.getById(req.params.entity, req.params.id);
    if (item === null) return res.status(404).json({ error: 'Not found' });
    res.json(item);
  } catch (err) {
    next(err);
  }
});

router.post('/:entity/batch', async (req, res, next) => {
  try {
    await store.saveMany(req.params.entity, req.body);
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

router.post('/:entity', async (req, res, next) => {
  try {
    await store.save(req.params.entity, req.body);
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

router.delete('/:entity/:id', async (req, res, next) => {
  try {
    await store.remove(req.params.entity, req.params.id);
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

router.delete('/:entity', async (req, res, next) => {
  try {
    await store.clear(req.params.entity);
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
