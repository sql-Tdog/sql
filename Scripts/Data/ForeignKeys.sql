  select k.name 'foreign key', t.name 'referencing table', t2.name 'referenced table', c.name 'referencing column', cr.name 'referenced column'
  from sys.foreign_keys k
  left join sys.tables t on t.object_id=k.parent_object_id
  left join sys.tables t2 on t2.object_id=k.referenced_object_id
  left join sys.foreign_key_columns fc ON fc.constraint_object_id=k.object_id
  left join sys.columns c ON c.object_id=k.parent_object_id AND c.column_id=fc.parent_column_id
  inner join sys.columns cr ON cr.object_id=k.referenced_object_id AND cr.column_id=fc.referenced_column_id
  where t2.name ='LookupAssisterStatus' 
