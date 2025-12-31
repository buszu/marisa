#include <ruby.h>
#include <marisa.h>

static VALUE mMarisa;
static VALUE cTrie;

static VALUE trie_initialize(VALUE self) {
  marisa::Trie *trie = new marisa::Trie();
  DATA_PTR(self) = trie;
  return self;
}

static void trie_free(void *ptr) {
  delete static_cast<marisa::Trie *>(ptr);
}

extern "C" void Init_marisa() {
  mMarisa = rb_define_module("Marisa");
  cTrie = rb_define_class_under(mMarisa, "Trie", rb_cObject);

  rb_define_alloc_func(cTrie, [](VALUE klass) {
    return Data_Wrap_Struct(klass, NULL, trie_free, nullptr);
  });

  rb_define_method(cTrie, "initialize", RUBY_METHOD_FUNC(trie_initialize), 0);
}
